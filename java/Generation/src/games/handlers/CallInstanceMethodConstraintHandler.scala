package games.handlers

import checkers.inference._
import games.GameSolver
import scala.collection.mutable.{ListBuffer, LinkedHashMap}
import verigames.level.{Board, Subboard, Chute, Intersection}
import verigames.level.Intersection.Kind._
import checkers.inference.CallInstanceMethodConstraint
import checkers.inference.FieldVP
import misc.util.VGJavaConversions._
import checkers.inference.InferenceMain._
import checkers.types.AnnotatedTypeMirror
import checkers.types.AnnotatedTypeMirror.{AnnotatedTypeVariable, AnnotatedDeclaredType}
import checkers.inference.util.CollectionUtil._
import games.util.SlotUtil._

/**
 * This class handles the creation/placement of a CALL to a method subboard and
 * NOT the creation of the a method subboard itself (this is done incrementally through
 * placement of individuals variables/constraints on a method board).
 *
 * At the moment, only the receiver variables and class type parameters are piped through
 * a method call intersections.  So we first split all variables before connecting them
 * to the method call intersection (i.e. the subboard intersection).  This also allows
 * us to handle the case in which the same variable is the argument to two different
 * method parameters.
 *
 * @param constraint The CallInstanceMethodConstraint that should be translated into a subboard intersection.
 * @param gameSolver The gameSolver singleton.
 */
case class CallInstanceMethodConstraintHandler( override val constraint : CallInstanceMethodConstraint,
                                                override val gameSolver : GameSolver)
  extends ConstraintHandler[CallInstanceMethodConstraint] {

  //NOTE: If a variable isn't declared in this file then it likely comes from gameSolver
  import gameSolver._

  val CallInstanceMethodConstraint(callerVp, classTypeArgsToBounds, methodTypeArgToBounds, argsToTypeParams,
                                   receiver, calledMethodVp, result) = constraint

  //The board representing the method IN which the call was made
  protected val callerBoard = variablePosToBoard(callerVp)

  // Variables that will be connected both as input/output of the subboard rather than just input or just output
  protected val throughVars = new ListBuffer[AbstractVariable]()

  // to avoid problems with arguments passed to two different params (i.e. aliased arguments),
  // we split before connecting each argument, and the next time the aliased argument
  // is used, we grab the split at the top, instead of pulling it up
  // from the output
  // TODO integrate this into more than just the receiver, once arguments flow through boards.
  protected val localIntersectionMap = new LinkedHashMap[Slot, Intersection]

  // stores all of the outputs from this subboard. Because aliased
  // arguments result in multiple outputs, we need to store a list.
  protected val outputMap = new LinkedHashMap[Slot, List[Intersection]]


  protected def addToOutputMap(slot: Slot, intersection: Intersection) = {
    outputMap.get(slot) match {
      case Some(list) => outputMap.update(slot, intersection::list)
      case None       => outputMap.update(slot, List(intersection))
    }
  }

  // checks localIntersection map for already-used arguments. If
  // nothing, uses the regular findIntersection method
  protected def localFindIntersection(slot: Slot): Intersection = {
    localIntersectionMap.get(slot) match {
      case Some(intersection) => intersection
      case None => findIntersection(callerBoard, slot)
    }
  }

  /**
   * Create the subboard intersection that represents the method call.  Connect all variables for the receiver,
   * class type parameters, and method type parameters through the intersection and link any that have an
   * equality relation ship.  Connect any variables for the method's arguments and link any generic type arguments
   * to their corresponding pipes in the method board.  At the moment we split the arguments rather than
   * routing them through but it should be enough to just route them through.  Connect the return type
   * through the subboard.
   */
  override def handle() {

    val subboardISect = addSubboardIntersection(callerBoard, calledMethodVp, calledMethodVp.getMethodSignature)

    connectReceiverParamsThrough( subboardISect )
    connectMethodTypeArgsThrough( subboardISect )

    //TODO JB: Add lower bound <: type arguments for methodTypeParams only as class type params should be handled

    connectLowerBoundsThrough( subboardISect )

    //TODO JB: Add lower bound <: argument is a use of class/method type param
    connectArgumentsThrough( subboardISect )

    connectResultAsOutput( subboardISect )

    capSplits()
    mergeOutputs()
  }

  //Connect the receivers main variable through the board
  //Connect the type arguments of the receiver through the class type parameters of the class
  //in which this method was defined
  //TODO: New widgets for handling non-defaultable locations
  def connectReceiverParamsThrough( subboardISect : Subboard ) = {
    val receiverVar = slotMgr.extractSlot( receiver )
    connectThrough( subboardISect, List( receiverVar -> false ), ReceiverInPort, ReceiverOutPort, false)

    //Connect the class type arguments of the receiver through corresponding ports
    val recvTypeArgsToLink = extractAndFlattenVariables( classTypeArgsToBounds.keys.toList )
    connectThrough( subboardISect, recvTypeArgsToLink, ClassTypeParamsInPort, ClassTypeParamsOutPort, false )
  }

  def connectMethodTypeArgsThrough( subboardISect : Subboard ) = {
    val methodTypeArgsToLink = extractAndFlattenVariables( methodTypeArgToBounds.keys.toList )
    connectThrough( subboardISect, methodTypeArgsToLink, MethodTypeParamsInPort, MethodTypeParamsOutPort, false )
  }

  def connectArgumentsThrough( subboardISect : Subboard ) = {
    val argToLinks = extractAndFlattenVariables( argsToTypeParams.keys.toList )
    connectThrough( subboardISect, argToLinks, ParamInPort, ParamOutPort, true)
  }

  //All the lower bounds of class type parameters and method type parameters are connected
  //The lower bounds should already have a pipe in the context of this method for the purposes
  //of enforcing the subtype constraint between the type argument
  def connectLowerBoundsThrough( subboardISect : Subboard ) = {
    val classTypeLBToLinks =
      classTypeArgsToBounds.values
        .map( _._2.asInstanceOf[AnnotatedTypeVariable].getEffectiveLowerBound )
        .map( slotMgr.extractSlot _ )
        .map( _ -> true )
        .toList

    connectThrough( subboardISect, classTypeLBToLinks, ClassTypeParamsInPort, ClassTypeParamsOutPort, false )

    val methodTypeLBToLinks =
      methodTypeArgToBounds.values
        .map( _._2.asInstanceOf[AnnotatedTypeVariable].getEffectiveLowerBound )
        .map( slotMgr.extractSlot _ )
        .map( _ -> true )
        .toList

    connectThrough( subboardISect, methodTypeLBToLinks, MethodTypeParamsInPort, MethodTypeParamsOutPort, false )
  }

  /**
   * This method takes a list of annotated type mirrors and returns a list of slots contained in
   * those annotated type mirrors in a tuple indicating whether or not we should link chutes representing the
   * variables to the corresponding chute in the subboard to which they will be attached.
   *
   * An AnnotatedTypeMirror is essentially a tree/tree node:
   *  e.g. @VarAnnot(0) List< @VarAnnot(1) >
   *  An ATM describing the above type is a tree with VarAnnot(0) at it's root and @VarAnnot(1) as it's descendant.
   *
   * Generally, when wiring the top level variables (e.g. VarAnnot(0) ) through a subboard the variable will be
   * a subtype of the corresponding chute in the method board represented by the subboard.  However, descendants
   * (e.g. VarAnnot(1) ) usually must be EQUAL to their corresponding chutes.
   *
   * Return a flat list where top level variables are identified by an accompanying FALSE value and
   * nested variables are accompanied by a TRUE value.  Preserve the order in which these variables are encountered.
   *
   * e.g.
   *  If I had a list of annotated type mirrors representing the following types:
   *    List( @0 List< @1 String >, @2 Map< @3 String, @4 Integer> )
   *
   *  Then the resulting output should be:
   *    List( @0 -> false, @1 -> true, @2 -> false, @3 -> true, @4 -> true )
   *
   * Note: This method is important because some port numbers are based on the sequence in which parameters
   * were added to the method (e.g. method arguments)
   * @param atms
   * @return
   */
  def extractAndFlattenVariables( atms : List[AnnotatedTypeMirror] ) : List[(Slot, Boolean)] = {
    topToNestedDeclVariables( atms )
      .map( topToNested => topToNested._1.map( _ -> false ) ++ topToNested._2.map( _ -> true ) )
      .flatten
  }


  def connectThrough( subboardISect : Subboard, slotToLinks : List[(Slot, Boolean)],
                      inputPortPrefix : String, outputPortPrefix : String, useIndex : Boolean ) {
    connectAsInput(  subboardISect, slotToLinks, inputPortPrefix,  useIndex )
    connectAsOutput( subboardISect, slotToLinks, outputPortPrefix, useIndex )
  }

  /**
   * Connect each variable chute on the caller board to the correct input of the subboard intersection
   * for this method call.  If the variable is not a unique slot (e.g. LiteralString("blahhhh")) then
   * it is a variable of some sort.  Split it, and add it's split into the local intersection map.
   *
   * @param subboardISect The subboard intersection being wired
   * @param slotToLinks   (slots -> link), the slots to wire and whether or not we wish to link them to
   *                      the corresponding pipe in the method subboard
   * @param portPrefix    A prefix to add to all input ports
   * @param addIndex      Should the index of a slot be added after portPrefix (but before any genericOffset)
   * @return A mapping of slots to the intersections that are created in this step.  For variables this is
   *         a mapping to the split created in this step.
   */
  def connectAsInput( subboardISect : Subboard, slotToLinks : List[(Slot, Boolean)],
                      portPrefix : String, addIndex : Boolean = false ) : List[(Slot,Intersection)] = {

    slotToLinks.zipWithIndex.map( slotToIndex => {
      val ( (slot, link), index) = slotToIndex

      //If a slot is unique (e.g. "someLiteral") then it doesn't need to be split because it can't be accessed again

      if ( isUniqueSlot( slot ) ) {
        val slotIsect = localFindIntersection( slot )
        val port = makePort( portPrefix, addIndex, index, slot, true )

        callerBoard.addEdge( slotIsect, "output", subboardISect, port, createChute( slot ) )
        slot -> slotIsect

      } else {
        val prevIntersection = localFindIntersection( slot )
        val port = makePort( portPrefix, addIndex, index, slot, false )

        if( link ) {
          //TODO JB: link the variable to the corresponding one in the method board
        }
        val split = callerBoard.add( prevIntersection, "output", SPLIT, "input", createChute( slot ) )._2
        callerBoard.addEdge(split, "split", subboardISect, port, createChute(slot ) )

        // it's a bit of a hack to update both the local and the
        // global intersection maps, but it won't be necessary once
        // all arguments are piped through
        localIntersectionMap.update( slot, split )
        slot -> split
      }
    })
  }


  /**
   * Connect each variable chute on the caller board to the correct input of the subboard intersection
   * for this method call.  If the variable is not a unique slot (e.g. LiteralString("blahhhh")) then
   * it is a variable of some sort.  Split it, and add it's split into the local intersection map.
   *
   * @param subboardISect The subboard intersection being wired
   * @param slotToLinks   (slots -> link), the slots to wire and whether or not we wish to link them to
   *                      the corresponding pipe in the method subboard
   * @param portPrefix    A prefix to add to all input ports
   * @param addIndex      Should the index of a slot be added after portPrefix (but before any genericOffset)
   * @return A mapping of slots to the intersections that are created in this step.  For variables this is
   *         a mapping to the split created in this step.
   */
  def connectAsOutput( subboardISect : Subboard, slotToLinks : List[(Slot, Boolean)],
                       portPrefix : String, addIndex : Boolean = false ) : List[(Slot,Intersection)] = {
    slotToLinks.zipWithIndex.map( slotToIndex => {
      val ( (slot, link), index) = slotToIndex

      //If a slot is unique (e.g. "someLiteral") then it doesn't need to be split because it can't be accessed again

      if ( isUniqueSlot( slot ) ) {
        val port = makePort( portPrefix, addIndex, index, slot, true )

        val connect = callerBoard.add( subboardISect, port, CONNECT, "input", createChute( slot ) )._2
        cap( slot, connect )

        slot -> connect

      } else {
        val port = makePort( portPrefix, addIndex, index, slot, false )

        if( link ) {
          //TODO JB: link the variable to the corresponding one in the method board
        }

        val connect = callerBoard.add( subboardISect, port, CONNECT, "input", createChute( slot ) )._2
        addToOutputMap(slot, connect)

        slot -> connect
      }
    })
  }

  def connectResultAsOutput( subboardISect : Subboard ) {
    // We may have multiple constraint variables for parameterized types and array types in the return type
    val resultVars = extractAndFlattenVariables( List( result ) )
    resultVars.foreach(
      _ match {

      case variable : AbstractVariable =>
        if (boardNVariableToIntersection.contains((callerBoard, variable))) {
          // Method was previously called.
          val resInt = boardNVariableToIntersection((callerBoard, variable))
          val merge = callerBoard.add(subboardISect, ReturnOutPort + genericsOffset(variable), MERGE, "left", toChute(variable))._2
          callerBoard.addEdge(resInt, "output", merge, "right", toChute(variable))
          boardNVariableToIntersection.update((callerBoard, variable), merge)

        } else {
          val con = callerBoard.add(subboardISect, ReturnOutPort + genericsOffset(variable), CONNECT, "input", toChute(variable))._2
          boardNVariableToIntersection.update((callerBoard, variable), con)
        }

      case _ =>
      // Nothing to do for void methods.
      // TODO: this is also for pre-annotated return types!
      // println("Unhandled return type slot! " + result)

    })

  }

  def cap( slot : Slot, isect : Intersection ) {
    callerBoard.add( isect, "toEnd", END, "input", createChute( slot ) )
  }

  def cap( slotToIsect : (Slot, Intersection)) {
    cap( slotToIsect._1, slotToIsect._2 )
  }

  /**
   * Any variable in the throughVars list has been piped through the board.  However, we also split this
   * variable at the top to handle aliased arguments (see localIntersectionMap).  End the extra split
   * as we will use the pipes coming out of the subboard as the latest intersection for these variables.
   */
  def capSplits() {
    localIntersectionMap.toList.foreach( slotToIsect=> cap( slotToIsect ) )
  }

  /**
   * Non-receiver arguments have not been piped through the board but may have resulted in multiple
   * splits of the same variable occurring above the method call intersections (for instance when
   * a call f.foo(bar, bar) would cause bar to be split twice).  These values will then be piped through
   * the method board and lead to potentially multiple output intersection for the same value.  Merge
   * these
   */
  def mergeOutputs() {
    for ((slot, subboardOutputs) <- outputMap) {
      val mergedIntersection = merge( subboardOutputs, () => createChute(slot) )
      updateIntersection(callerBoard, slot, mergedIntersection)
    }
  }

  // Arguments:
  // - list of intersections
  // - a factory with which new chutes can be created
  //
  // Effects:
  // adds enough merges to merge the intersections into a single
  // pipe
  //
  // Returns: the single node resulting from this process (which may
  // be a merge node, or may be another node, if no merges were
  // needed)
  //
  // Mutates: callerBoard
  def merge(intersections: List[Intersection], chuteFactory: () => Chute): Intersection = intersections match {
    // if there's only one intersection, just return that one
    case hd::Nil => hd
    case first :: second :: tl => {
      val mergeIntersection = callerBoard.add(first, "toMerge", MERGE, "first", chuteFactory())._2
      callerBoard.addEdge(second, "toMerge", mergeIntersection, "second", chuteFactory())
      merge(mergeIntersection :: tl, chuteFactory)
    }
    case Nil => throw new IllegalArgumentException("empty list passed to merge")
  }


  /**
   * Create
   * @param portPrefix
   * @param addIndex
   * @param index
   * @param slot
   * @param unique
   * @return
   */
  def makePort(portPrefix : String, addIndex : Boolean, index : Int, slot : Slot, unique : Boolean) : String = {
    val port = new scala.collection.mutable.StringBuilder()
    port ++= portPrefix

    if( addIndex ) {
      port ++= index.toString
    }

    if( !unique ) {
      port ++= genericsOffset( slot.asInstanceOf[AbstractVariable] ).toString
    }

    port.toString
  }

}
