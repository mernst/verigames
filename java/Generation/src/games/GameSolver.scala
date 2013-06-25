package games

import checkers.inference._
import javacutils.AnnotationUtils
import scala.collection.mutable.HashMap
import scala.collection.mutable.LinkedHashMap
import scala.collection.mutable.Queue
import com.sun.source.tree.Tree.Kind
import javax.lang.model.element.AnnotationMirror
import verigames.level._
import checkers.inference.LiteralNull
import checkers.inference.AbstractLiteral
import util.VGJavaConversions._
import verigames.level.Intersection.Kind._
import checkers.inference.FieldAssignmentConstraint
import checkers.inference.WeightInfo
import checkers.inference.CombineConstraint
import checkers.inference.AssignmentConstraint
import checkers.inference.NewInStaticInitVP
import scala.Some
import checkers.inference.Variable
import checkers.inference.ParameterVP
import checkers.inference.NewInMethodVP
import checkers.inference.Constant
import checkers.inference.CallInstanceMethodConstraint
import checkers.inference.CombVariable
import checkers.inference.FieldAccessConstraint
import checkers.inference.ReturnVP
import checkers.inference.ComparableConstraint
import checkers.inference.RefinementVariable
import checkers.inference.FieldVP
import checkers.inference.NewInFieldInitVP
import verigames.layout.LayoutDebugger

import scala.collection.JavaConversions._

/**
 * An abstract base class for all game solvers.
 */
abstract class GameSolver extends ConstraintSolver {

    //TODO JB: TEMP KLUDGE FOR UNSUPPORTED VARIABLES
    var unsupportedVariables = new scala.collection.mutable.ListBuffer[Variable]

    /** All variables declared in this program. */
    var variables: List[Variable] = null

    /** Empty, b/c there is no viewpoint adaptation (yet?). */  //TODO: Is this true?
    var combvariables: List[CombVariable] = null

    /** flow-sensitively refined variables.  Each one of these variables corresponds to a
     * declared variable after an assignment operation
     */
    var refinementVariables: List[RefinementVariable] = null

    /** All constraints that have to be fulfilled. */
    var constraints: List[Constraint] = null

    /** Weighting information. Currently empty & ignored, as a human solves the game. */
    var weights: List[WeightInfo] = null

    /** The command-line parameters. */
    var params: TTIRun = null

    /**
     * We generate a separate level for every class.
     * The key is the fully-qualified class name and the
     * value is the corresponding level.
     */
    val classToLevel = new LinkedHashMap[String, Level]

    /**
     * We generate one board for every class that contains the field
     * initializers (other top-level things?).
     * The key is the fully-qualified class name and the
     * value is the corresponding board.
     */
    val  classToBoard = new LinkedHashMap[String, Board]

    /** We generate a separate board for every method within a class.
     * The key is the fully-qualified class name followed by the method
     * signature and the value is the corresponding board.
     */
    val methToBoard = new LinkedHashMap[String, Board]

    /**
     * For each constraint variable we keep a reference to the
     * Intersection that should be used as next input.
     * For local slots that would be unique enough; however, fields and
     * method parameters/returns occur on multiple boards. Therefore,
     * the key in the map is a pair of Board and Variable.
     * Output port 0 of the Intersection has to be free.
     */
    val boardNVariableToIntersection = new LinkedHashMap[(Board, AbstractVariable), Intersection]

    /**
     * Mapping from a board to the Intersection that represents the "this" literal.
     */
    val boardToSelfIntersection = new LinkedHashMap[Board, Intersection]


    def solve(variables: List[Variable],
    combvariables: List[CombVariable],
    refinementVariables : List[RefinementVariable],
    constraints: List[Constraint],
    weights: List[WeightInfo],
    params: TTIRun): Option[Map[AbstractVariable, AnnotationMirror]] = {

      this.variables = variables
      this.combvariables = combvariables
      this.refinementVariables = refinementVariables
      this.constraints = constraints
      this.weights = weights
      this.params = params

      println("Creating world")
      // Create the world!
      val world = createWorld()

      println("Determining layout")
      // Assign a layout to the world.
      verigames.layout.WorldLayout.layout(world)

      println("Writing XML output")
      // TODO: add an option for the file name
      val xmlFile = new java.io.File("World.xml") // params.optWorldXMLFileName)
      // TODO: check for existing file
      val output = new java.io.PrintStream(new java.io.FileOutputStream(xmlFile))
      new WorldXMLPrinter().print(world, output, null)
      output.close()

      // Return as solution a mapping back to the variable IDs. This results in
      // an AFU file with "@checkers.inference.quals.VarAnnot(42)" being written.
      // When the interactive part is done it can simply replace these placeholders
      // with the inferred solutions.
      // TODO: pass the variable IDs to the correct nodes in the World.
      val res = new HashMap[AbstractVariable, AnnotationMirror]
      variables foreach { v => {
        res += (v -> v.getAnnotation())
      }}
      Some(res.toMap)
    }

    def toChute(cvar : AbstractVariable) = new Chute(cvar.id, cvar.toString())

    // InferenceMain already measures the time that the solver overall takes.
    // We cannot measure the time used by the human, so just suppress this.
    def timing: String = null

    def version: String = "GameSolver version 0.1\n" +
      "WorldXMLPrinter version " + WorldXMLPrinter.version +
      " WorldXMLParser version " + WorldXMLParser.version

    /**
     * Create the world!
     */
    def createWorld(): World = {

      val world = new World()

      try {

      // First create all the levels and boards.
      createBoards(world)
      // Then represent all the constraints.
      handleConstraints(world)
      // Optimize the world, removing unnecessary complexity.
      optimizeWorld(world)

      // Finally, add any necessary plumbing to the end of each board.
      // ANd add the boards to the world
      finalizeWorld(world)

        val printWorld = Option(System.getProperty("PRINT_WORLD") )
        if( printWorld.map( _ == "true" ).getOrElse(false) ) {
          LayoutDebugger.layout(world, "./debug_world");
        }
      }
      catch {
        case exc : Exception => LayoutDebugger.layout(world, "./debug_world")
                                throw exc
      }

      world
    }

    /**
     * First, go through all variables and create a level for each occurring
     * class and a board for each occurring method.
     */
    def createBoards(world: World) {
      variables foreach { cvar => {
        import Intersection.Kind._

        val level = variablePosToLevel(cvar.varpos)
        val board = variablePosToBoard(cvar.varpos)

        cvar.varpos match {

          //WithinMethodVP cases
          case mvar: ParameterVP =>
            // For each parameter, create a CONNECT Intersection.
            // Also for FieldVP, but that's not an InMethodVP...
            val incoming = board.getIncomingNode
            val connect = board.add(incoming, ParamInPort+incoming.getOutputIDs().size(),
                                    CONNECT, "input", toChute(cvar))._2
            boardNVariableToIntersection += ((board, cvar) -> connect)

          case mvar: NewInMethodVP =>
            // For object creations, add a START_SMALL_BALL Intersection.
            val connect = board.add(START_SMALL_BALL, "output", CONNECT, "input", toChute(cvar))._2
            boardNVariableToIntersection += ( (board, cvar) -> connect )

          case mtp : MethodTypeParameterVP  =>
            //TODO: Is ordering going to be a problem?
            val incoming = board.getIncomingNode
            val connect = board.add(incoming, ParamInPort+incoming.getOutputIDs().size() + genericsOffset(cvar),
              CONNECT, "input", toChute(cvar))._2
            boardNVariableToIntersection += ((board, cvar) -> connect)


          case mvar: WithinMethodVP =>
            // For returns, locals, casts, and instance-ofs, add a START_NO_BALL Intersections.  //TODO: Add refinement vars here?
            // TODO: Should a local variable start as BLACK/WHITE or NO ball?
            val connect = board.add(START_NO_BALL, "output", CONNECT, "input", toChute(cvar))._2
            boardNVariableToIntersection += ((board, cvar) -> connect)

          //WithinClassVP cases
          case clvar : FieldVP =>  {
            // For a field type, create three things.
            // 1. For field initializers, add the initial connects
            {
              val incoming = board.getIncomingNode
              val connect  = board.add(incoming, OutputPort+incoming.getOutputIDs().size(),
                                             CONNECT, "input", toChute(cvar))._2
              boardNVariableToIntersection += ((board, cvar) -> connect)
            }

            // 2. a field getter
            {
              // val getterBoard = newBoard(level, getFieldAccessorName(clvar.asInstanceOf[FieldVP]))
              val getterBoard = findOrCreateMethodBoard(clvar, getFieldAccessorName(clvar))
              val inthis = findIntersection(getterBoard, LiteralThis)
              getterBoard.add(START_PIPE_DEPENDENT_BALL, "output", getterBoard.getOutgoingNode, ReturnOutPort + (1 + genericsOffset(cvar)), toChute(cvar))
            }

            // 3. a field setter
            {
              // val setterBoard = newBoard(level, getFieldSetterName(clvar.asInstanceOf[FieldVP]))
              val setterBoard = findOrCreateMethodBoard(clvar, getFieldSetterName(clvar))
              val inthis = findIntersection(setterBoard, LiteralThis)
              setterBoard.add(setterBoard.getIncomingNode, OutputPort + (1 + genericsOffset(cvar)),
                              END, "input", toChute(cvar))
              // Let's not have an output for setters.
              // setterBoard.addEdge(field, 0, outgoing, 1, new Chute(cvar.id, cvar.toString()))
            }
          }

          //Add a connection for type variables to a classes type parameters to a class
          //board in case they are
          /*case ctp : ClassTypeParameterVP  =>
            val connect = board.add(START_NO_BALL, "output", CONNECT, "input", toChute(cvar))._2
            boardNVariableToIntersection += ((board, cvar) -> connect) */

          case clVar: WithinClassVP if ( clVar.isInstanceOf[NewInFieldInitVP] ||
                                         clVar.isInstanceOf[NewInStaticInitVP] )  =>
              val connect = board.add(START_SMALL_BALL, "output", CONNECT, "input", toChute(cvar))._2
              // For object creations, add a START_WHITE_BALL Intersection.
              boardNVariableToIntersection += ((board, cvar) -> connect)

          case clvar: WithinClassVP if ( cvar.varpos.isInstanceOf[WithinFieldVP]     ||
                                         cvar.varpos.isInstanceOf[WithinStaticInitVP] ) =>
            val connect = board.add(START_NO_BALL, "output", CONNECT, "input", toChute(cvar))._2
            boardNVariableToIntersection += ((board, cvar) -> connect)

          case clvar: WithinClassVP =>
            unsupportedVariables += cvar
            println("TODO: unsupported field variable position: " + cvar + " pos: " + clvar.getClass())

          case _ =>
            unsupportedVariables += cvar
            println("TODO: unhandled position for: " + cvar + " pos: " + cvar.varpos.getClass())

        }
      }}

      refinementVariables.foreach(
        refVar => {
          //create the refinement variable no ball start
          val board = variablePosToBoard(refVar.varpos)
          val connect = board.add(START_NO_BALL, "output", CONNECT, "input", toChute(refVar))._2
          boardNVariableToIntersection += ((board, refVar) -> connect)

          //enforce the subtype rule of refinement <: declaration
          //TODO: I don't like calling handleConstraint here but I also don't
          //TODO: Like duplicating the handling of Subtype relationships
          handleConstraint(world, SubtypeConstraint(refVar, refVar.declVar))
        }
      )
    }


    /**
     * Go through all constraints and add the corresponding piping to the boards.
     */
    def handleConstraints(world: World) {
      var workList = List[Constraint](constraints :_*)

      while (!workList.isEmpty) {
        val initialSize = workList.size
        workList = workList.filterNot( constraint => handleConstraint(world, constraint) )

        if (workList.size == initialSize) {
          throw new IllegalStateException("Constraints not solvable: \n" + workList.mkString("\n"))
        }
      }
    }


    val ParamInPort     = "inParam"
    val ReceiverInPort  = "inReceiver"
    val ReceiverOutPort = "outReceiver"
    val ReturnOutPort   = "outputReturn"
    val OutputPort      = "output_"            //TODO: Standardize on a scheme
    val InputPort       = "input_"

    /*
     * Handles a constraint (adding necessary nodes and edges) for the given world.
     * Returns true if the constraint was successfully handled. Does not mutate and returns
     * false if the constraint was not successfully handled.
     */ 
    def handleConstraint(world: World, constraint: Constraint): Boolean = {
        import Intersection.Kind._
        constraint match {
          case comp: ComparableConstraint =>
            println("TODO: support comparable constraints!")

          case cc: CombineConstraint =>
            println("TODO: combine constraints should never happen!")

          case FieldAccessConstraint(accessContext, receiver, fieldslot, fieldvp, secondaryVars) =>
            val accessBoard = variablePosToBoard(accessContext)
            val getterSubboardIsect = addSubboardIntersection(accessBoard, fieldvp, getFieldAccessorName(fieldvp))

            { // Connect the receiver to input and output 0
              val receiverInt = findIntersection(accessBoard, receiver) //TODO JB: Does this do the correct thing for other.field?
              accessBoard.addEdge(receiverInt, "output", getterSubboardIsect, ReceiverInPort, createChute(receiver))
              val con = accessBoard.add(getterSubboardIsect, ReceiverOutPort, CONNECT, "input", createChute(receiver))._2

              updateIntersection(accessBoard, receiver, con)
            }
            { // Connect the result as output only
              fieldslot match {
                case fieldvar: Variable => {
                  if (boardNVariableToIntersection.contains((accessBoard, fieldvar))) {
                    // Field was previously accessed.
                    val fieldInt = boardNVariableToIntersection((accessBoard, fieldvar))

                    val merge = accessBoard.add(getterSubboardIsect, ReturnOutPort + (1 + genericsOffset(fieldvar)), MERGE, "left", toChute(fieldvar))._2
                    accessBoard.addEdge(fieldInt, "output", merge, "right", toChute(fieldvar))
                    boardNVariableToIntersection.update((accessBoard, fieldvar), merge)
                  } else {

                    val con = accessBoard.add(getterSubboardIsect,  ReturnOutPort + (1 + genericsOffset(fieldvar)), CONNECT, "input", toChute(fieldvar))._2
                    boardNVariableToIntersection.update((accessBoard, fieldvar), con)
                  }
                }
                case _ => {
                  println("Unhandled field type slot! " + fieldslot)
                }
              }

              // For type parameterized variables, add type parameter outputs to getter subboard
              for( sVar <- secondaryVars ) {
                //TODO JB: Handle Constants/ Literals - create the type pipes if they don't already exist?
                if( sVar.isInstanceOf[AbstractVariable] ) { //TODO JB: This will be fixed with using ATMs for Constraints
                  val absSVar = sVar.asInstanceOf[AbstractVariable]
                  val con = accessBoard.add(getterSubboardIsect, ReturnOutPort + (1 + genericsOffset(absSVar)), CONNECT, "input", toChute(absSVar))._2
                  boardNVariableToIntersection.update((accessBoard, absSVar), con)
                }
              }
            }

          case FieldAssignmentConstraint(context, recvslot, fieldslot, rightslot) =>
            //TODO JB:  This needs to be fixed, run on Picard histograms, and example would be Double d = 7.0/7.0;
            //TODO POSSIBILITY: Create constants for these types while the unboxing op is visited by the DFF?
            if(rightslot == null) {
              return true
            }

            val ctxBoard = variablePosToBoard(context)
            fieldslot match {
              case fieldvar : Variable => {
                fieldvar.varpos match {
                  case fvp: FieldVP => {
                    val setterBoardISect = addSubboardIntersection(ctxBoard, fvp, getFieldSetterName(fvp))
                    val recvInt = findIntersection(ctxBoard, recvslot)
                    ctxBoard.addEdge(recvInt, "output", setterBoardISect, ReceiverInPort, createChute(recvslot))

                    if (isUniqueSlot(rightslot)) {
                      val rightInt = findIntersection(ctxBoard, rightslot)
                      ctxBoard.addEdge(rightInt, "output", setterBoardISect, OutputPort + (1 + genericsOffset(fieldvar)), createChute(rightslot))

                    } else {
                      val rightInt =
                       try {
                         findIntersection(ctxBoard, rightslot)
                      } catch{
                        case exc : NoSuchElementException =>
                          val ints = this.boardNVariableToIntersection.filterKeys(_._1 == ctxBoard)
                          return true    //TODO JB: This is likely Generics related and should be removed in the future
                        case _ => null //TODO JB: Completely erroneous
                      }
                      val split = ctxBoard.add(rightInt, "output", SPLIT, "input", createChute(rightslot))._2
                      ctxBoard.addEdge(split, "split", setterBoardISect, OutputPort + (1 + genericsOffset(fieldvar)), createChute(rightslot))

                      updateIntersection(ctxBoard, rightslot, split)
                    }

                    val con = ctxBoard.add(setterBoardISect, ReceiverOutPort, CONNECT, "input", createChute(recvslot))._2
                    updateIntersection(ctxBoard, recvslot, con)
                  }
                  case _ => {
                    println("Unhandled FieldAssignmentConstraint: " + constraint)
                  }
                }
              }
              case _ => {
                println("Unhandled FieldAssignmentConstraint: " + constraint)
              }
            }

          case AssignmentConstraint(context, leftslot, rightslot) =>
            println("TODO: AssignmentConstraint not handled")

          case CallInstanceMethodConstraint(caller, receiver, methname, tyargs, args, result) => {

            val callerBoard = variablePosToBoard(caller)
            val subboard = addSubboardIntersection(callerBoard, methname, methname.getMethodSignature)
            // The input port to use next
            var subboardPort = 0

            // to avoid problems with aliased arguments, we split before
            // connecting each argument, and the next time the aliased argument
            // is used, we grab the split at the top, instead of pulling it up
            // from the output
            // TODO integrate this into more than just the receiver, once
            // arguments flow through boards.
            val localIntersectionMap = new LinkedHashMap[Slot, Intersection]
            // stores all of the outputs from this subboard. Because aliased
            // arguments result in multiple outputs, we need to store a list.
            val outputMap = new LinkedHashMap[Slot, List[Intersection]]
            // checks localIntersection map for already-used arguments. If
            // nothing, uses the regular findIntersection method
            def localFindIntersection(slot: Slot): Intersection = {
              localIntersectionMap.get(slot) match {
                case Some(intersection) => intersection
                case None => findIntersection(callerBoard, slot)
              }
            }

            def addToOutputMap(slot: Slot, intersection: Intersection) = {
              outputMap.get(slot) match {
                case Some(list) => outputMap.update(slot, intersection::list)
                case None     => outputMap.update(slot, List(intersection))
              }
            }

            { // Connect the receiver to input and output 0
              val receiverIntersection = try {  //TODO JB: REMOVE THIS
                localFindIntersection(receiver)
              } catch {
                case nsb : NoSuchElementException => return true
              }
              // split so that if the argument is aliased, we have something
              // above the subboard to connect to.
              val split = callerBoard.add(receiverIntersection, "toSplit", SPLIT, "input", createChute(receiver))._2
              callerBoard.addEdge(split, "toSubboard", subboard, ReceiverInPort, createChute(receiver))
              localIntersectionMap.update(receiver, split)

              // pipe the receiver through the subboard
              val connect = callerBoard.add(subboard, ReceiverOutPort, CONNECT, "input", createChute(receiver))._2

              addToOutputMap(receiver, connect)
            }
            {
              //TODO: Existing problem is HERE!!
              val typeArgs = tyargs
              receiver match {

                //a method call on this will still need the classes type parameters to be piped through
                case LiteralThis => //TODO: are static imports properly mapped?

                case field : FieldVP => //TODO: Does this make sense?

                //case static class method  -- T

                //case local object

                case _ => //What are the other possibilities

              }



              //If caller == receiver => Pipe through class type args?

              //TODO: Need to do the type arguments for the receiver and for the method (i.e. those that
              //TODO: appear in the method declaration and those that appear


              // TODO: type arguments
              //1. Find the super type in which the type arguments for this method were declared
              //2. Match these type arguments with the correct positions
              //3. Attach to the output of the previous intersection which should be a subboard for field access
              //4.

            }
            { // Connect the arguments as inputs only
              val arg2 = args     //TODO: Remove this, it's only here for scala debugging purposes
              for (anarg <- args) {
                subboardPort += 1

                // TODO: merge this with RHS of assignment
                if (isUniqueSlot(anarg)) {
                  val anargInt = localFindIntersection(anarg)
                  callerBoard.addEdge(anargInt, "output", subboard, ParamInPort + subboardPort, createChute(anarg))
                } else {
                  val anargInt = localFindIntersection(anarg)

                  val split = callerBoard.add(anargInt, "output", SPLIT, "input", createChute(anarg))._2
                  callerBoard.addEdge(split, "split", subboard, ParamInPort + subboardPort, createChute(anarg))

                  // it's a bit of a hack to update both the local and the
                  // global intersection maps, but it won't be necessary once
                  // all arguments are piped through
                  localIntersectionMap.update(anarg, split)
                  updateIntersection(callerBoard, anarg, split)
                }
              }

              // clean up:
              // - add end nodes to all of the splits above the subboard that
              //   are unused
              // - merge any outputs that correspond to the same argument
              // - call updateIntersection for each argument

              // the receiver is currently the only argument that is piped
              // through and split on the top, so it's the only one that could
              // have dangling splits above the subboard.
              val receiverSplit = localIntersectionMap.getOrElse(receiver, null)
              val end = callerBoard.add(receiverSplit, "toEnd", END, "input", createChute(receiver))._2

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
                case first::second::tl => {
                  val mergeIntersection = callerBoard.add(first, "toMerge", MERGE, "first", chuteFactory())._2
                  callerBoard.addEdge(second, "toMerge", mergeIntersection, "second", chuteFactory())
                  merge(mergeIntersection::tl, chuteFactory)
                }
                case Nil => throw new IllegalArgumentException("empty list passed to merge")
              }

              for ((slot, subboardOutputs) <- outputMap) {
                val mergedIntersection = merge(subboardOutputs, () => createChute(slot))
                updateIntersection(callerBoard, slot, mergedIntersection)
              }
            }
            { // We may have multiple constraint variables for parameterized types and array types in the return type
              result.foreach( _ match {

                case resvar: Variable =>
                  if (boardNVariableToIntersection.contains((callerBoard, resvar))) {
                    // Method was previously called.
                    val resInt = boardNVariableToIntersection((callerBoard, resvar))
                    val merge = callerBoard.add(subboard, ReturnOutPort + (1 + genericsOffset(resvar)), MERGE, "left", toChute(resvar))._2
                    callerBoard.addEdge(resInt, "output", merge, "right", toChute(resvar))
                    boardNVariableToIntersection.update((callerBoard, resvar), merge)

                  } else {
                    val con = callerBoard.add(subboard, ReturnOutPort + (1 + genericsOffset(resvar)), CONNECT, "input", toChute(resvar))._2
                    boardNVariableToIntersection.update((callerBoard, resvar), con)
                  }

                case _ =>
                  // Nothing to do for void methods.
                  // TODO: this is also for pre-annotated return types!
                  // println("Unhandled return type slot! " + result)

              })
            }
          }
          case _ =>
            // Don't do anything here and hope the subclass does something.

        }
        return true
    }

    /**
     * Type-system independent optimizations of the world.
     */
    def optimizeWorld(world: World) {/*

      val emptyLevels = new collection.mutable.ListBuffer[String]
      world.getLevels() foreach ( kv => { val (levelName, level) = kv
        var levelEmpty = true
        level.getBoards() foreach ( kv => { val (boardName, board) = kv
          if (!board.getEdges().isEmpty()) {
            println("Board with edges: " + board.getEdges())
            levelEmpty = false
          }
        })
        if (levelEmpty) {
          emptyLevels.add(levelName)
        }
      })
      println("Empty levxxxels: " + emptyLevels)
      */
    }

    /**
     * Finalize the world by closing the scope of all variables and adding
     * the necessary edges to the output.
     */
    def finalizeWorld(world: World) {
      // Connect all intersections to the corresponding outgoing slot
      // boardNVariableToIntersection foreach ( kv => { val ((board, cvar), lastsect) = kv
        boardNVariableToIntersection foreach { case ((board, cvar), lastsect) => {
        if (cvar.varpos.isInstanceOf[ReturnVP] && variablePosToBoard(cvar.varpos) == board) {
          // Only the return variable is attached to outgoing.
          val outgoing = board.getOutgoingNode()
          board.addEdge(lastsect, "output", outgoing, ReturnOutPort + (1 + genericsOffset(cvar)), toChute(cvar))
        } else {
          // Everything else simply gets terminated.
          val end = board.add(lastsect, "output", Intersection.Kind.END, "input", toChute(cvar))._2
        }

      }}

      boardToSelfIntersection foreach { case (board, lastsect) =>
        val outgoing = board.getOutgoingNode()
        val outthis = createThisChute()
        board.addEdge(lastsect, "output", outgoing, ReceiverOutPort, outthis)
      }

      // Finally, deactivate all levels and add them to the world.
      classToLevel foreach { case (cname, level) =>
          level.finishConstruction()
          world.addLevel(cname, level)
      }
    }

    def findIntersection(board: Board, slot: Slot): Intersection

        def createThisChute(): Chute
    def createChute(slot: Slot): Chute
    def updateIntersection(board: Board, slot: Slot, inters: Intersection)


    /**
     * Create a new board within the given level.
     * Sanitizes the name to be a valid XML ID.
     */
    def newBoard(level: Level, name: String): Board = {
      val b = new Board("Level=" + level + " Board=" + name + "")
      // println("created board " + b + " with name " + name)
      val cleanname = cleanUpForXML(name)
      level.addBoard(cleanname, b)

      b.addNode(Intersection.factory(Intersection.Kind.INCOMING))
      b.addNode(Intersection.factory(Intersection.Kind.OUTGOING))

      b
    }

    /**
     * Create a new subboard intersection and ensure that the board corresponding to the
     * subboard has already been created
     */
    def addSubboardIntersection(callerBoard: Board, calledvarpos: VariablePosition, calledname: String): Subboard = {
      val subboard = Intersection.subboardFactory(cleanUpForXML(calledname))
      callerBoard.addNode(subboard)
      // Ensure that called board exists, returned board not used.
      findOrCreateMethodBoard(calledvarpos, calledname)
      subboard
    }

    def variablePosToLevel(varpos: VariablePosition): Level = {
      val fqcname = varpos match {
        case mvar: WithinMethodVP => {
          mvar.getFQClassName
        }
        case clvar: WithinClassVP => {
          clvar.getFQClassName
        }
        case _ => {
          println("variablePosToLevel: unhandled position: " + varpos)
          null
        }
      }

      // Create/Find the level for the class.
      val level: Level = if (classToLevel.contains(fqcname)) {
          classToLevel(fqcname)
      } else {
          val l = new Level
          classToLevel += (fqcname -> l)
          l
      }
      level
    }

    /**
     * Look up the board for a given variable position.
     */
    def variablePosToBoard(varpos: VariablePosition): Board = {
      varpos match {
        case mvar: WithinMethodVP => {
          val msig = mvar.getMethodSignature
          findOrCreateMethodBoard(varpos, msig)
        }
        case clvar: WithinClassVP => {
          val fqcname = clvar.getFQClassName

          if (classToBoard.contains(fqcname)) {
            classToBoard(fqcname)
          } else {
            val level = variablePosToLevel(varpos)
            val b = newBoard(level, fqcname)
            classToBoard += (fqcname -> b)
            addThisStart(b)
            b
          }
        }
        case _ => {
          println("variablePosToBoard: unhandled position: " + varpos)
          null
        }
      }
    }

    def findOrCreateMethodBoard(varpos: VariablePosition, sig: String): Board = {
      if (methToBoard.contains(sig)) {
        methToBoard(sig)
      } else {
        val level = variablePosToLevel(varpos)
        val b = newBoard(level, sig)
        methToBoard += (sig -> b)
        // TODO: handle static methods
        addThisStart(b)
        b
      }
    }

    /** Add the beginning of "this" pipes to a board. */
    def addThisStart(board: Board) {
      val incoming = board.getIncomingNode()
      val inthis = createThisChute()
      val connect = board.add(incoming, ReceiverInPort, Intersection.Kind.CONNECT, "input", inthis)._2
      boardToSelfIntersection += (board -> connect)
    }

    /**
     * Find the board that should be used for a constraint between two
     * slots.
     */
    def findBoard(slot1: Slot, slot2: Slot): Board = {

      def varPositionsToBoard(varPos1 : VariablePosition, varPos2 : VariablePosition) = {
        val board1 = variablePosToBoard(varPos1)
        val board2 = variablePosToBoard(varPos2)

        if (board1==board2) {
          board1
        } else if (varPos1.isInstanceOf[ReturnVP]) {
          board2
        } else if (varPos2.isInstanceOf[ReturnVP]) {
          board2
        } else {
          /* We only need to handle variables that will end up on the same board.
           * For all other variables, there will be a MethodCall, FieldRead, or FieldUpdate
           * constraint, that links things together.
           */
          null
        }
      }

      def varPositionAndLiteralToBoard(varPos : VariablePosition, literal : AbstractLiteral) = {
        if (varPos.isInstanceOf[ParameterVP]) {
          null
        } else {
          variablePosToBoard(varPos)
        }
      }

      (slot1, slot2) match {
        case (cvar1: Variable, cvar2: Variable) => varPositionsToBoard(cvar1.varpos, cvar2.varpos)

        case (cvar: Variable, refVar: RefinementVariable) => varPositionsToBoard(cvar.varpos, refVar.varpos)
        case (refVar: RefinementVariable, cvar: Variable) => varPositionsToBoard(cvar.varpos, refVar.varpos)

        case (cvar: Variable, lit: AbstractLiteral)  => varPositionAndLiteralToBoard(cvar.varpos, lit)
        case (lit: AbstractLiteral, cvar: Variable)  => varPositionAndLiteralToBoard(cvar.varpos, lit)

        case (refVar: RefinementVariable, lit: AbstractLiteral)  => varPositionAndLiteralToBoard(refVar.declVar.varpos, lit)
        case (lit: AbstractLiteral, refVar: RefinementVariable)  => varPositionAndLiteralToBoard(refVar.declVar.varpos, lit)

        case (cvar1: Variable, c: Constant) => variablePosToBoard(cvar1.varpos)
        case (c: Constant, cvar2: Variable) => variablePosToBoard(cvar2.varpos)

        case (refVar: RefinementVariable, c: Constant) => variablePosToBoard(refVar.declVar.varpos)
        case (c: Constant, refVar: RefinementVariable) => variablePosToBoard(refVar.declVar.varpos)

        // TODO: Combvariables appear for BinaryTrees.
        case (cv: CombVariable, cvar2: Variable)            => variablePosToBoard(cvar2.varpos)
        case (cv: CombVariable, refVar: RefinementVariable) => variablePosToBoard(refVar.declVar.varpos)

        case (_, _) => {
          println("TODO: findBoard unhandled slots: " + slot1 + " and " + slot2)
          null
        }
      }
    }

    /**
     * Sanitize a string to make it a suitable XML identifier.
     */
    def cleanUpForXML(name: String): String =
      replaceAll(name, Map(
            '(' -> '-',
            ')' -> '-',
            ':' -> '-',
            '#' -> '-',
            ';' -> '-',
            '/' -> '-',
            // Constructors are named "<init>" and "<cinit>"
            '<' -> '-',
            '>' -> '-',
            // Arrays in bytecode
            '[' -> '-'
      ))

    def replaceAll(str : String, transforms : Map[Char,Char]) =
      transforms.foldLeft(str)( (old, cur) => old.replace(cur._1, cur._2) )

    /** For "unique" slots we do not need to create splits, as a new, unique
     * intersection is generated each time.
     */
    def isUniqueSlot(slot: Slot): Boolean = {
      !(slot.isInstanceOf[Variable] || slot.isInstanceOf[RefinementVariable] || slot == LiteralThis)
    }

    /**
     * Helper method to determine the name of the subboard used for a field getter.
     */
    def getFieldAccessorName(fvp: FieldVP): String = {
      fvp.getFQName + "--GET"
    }

    /**
     * Helper method to determine the name of the subboard used for a field setter.
     */
    def getFieldSetterName(fvp: FieldVP): String = {
      fvp.getFQName + "--SET"
    }

    /** Determine the offset for the generic location of the variable,
     * that is, if we want to serialize all the variables for input/output
     * to subboards, what port number should be used.
     */
    def genericsOffset(avar: AbstractVariable): Int = {
      if (avar.pos==null || avar.pos.size==0) {
        0
      } else {
        // Add up the size of the array plus all the elements in the array.
        // Is this unique?
        (avar.pos.size /: avar.pos) (_ + _)
      }
    }
}