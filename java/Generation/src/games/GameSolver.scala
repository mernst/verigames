package games

import checkers.inference._
import javacutils.AnnotationUtils
import scala.collection.mutable.HashMap
import scala.collection.mutable.LinkedHashMap
import scala.collection.mutable.Queue
import com.sun.source.tree.Tree.Kind
import javax.lang.model.element.AnnotationMirror
import verigames.level._
import checkers.inference._
import misc.util.VGJavaConversions._
import verigames.level.Intersection.Kind._
import verigames.layout.LayoutDebugger

import scala.collection.JavaConversions._
import games.handlers.{StaticMethodCallConstraintHandler, InstanceMethodCallConstraintHandler, FieldAssignmentConstraintHandler, FieldAccessConstraintHandler}
import checkers.inference.util.CollectionUtil
import checkers.types.AnnotatedTypeMirror

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
     * We need to be able to route a class's type parameters through all
     * setters/getters.  Therefore, we must the type parameters to add them
     * to the relevant board
     */
    val classToTypeParams = new LinkedHashMap[String, java.util.List[AbstractVariable]]


    val fieldBoardsToClass = new LinkedHashMap[Board, String]

    /**
     * For each constraint variable we keep a reference to the
     * Intersection that should be used as next input.
     * For local slots that would be unique enough; however, fields and
     * method parameters/returns occur on multiple boards. Therefore,
     * the key in the map is a pair of Board and Variable.
     * Output port 0 of the Intersection has to be free.
     */
    val boardNVariableToIntersection = new LinkedHashMap[(Board, AbstractVariable), Intersection]

    //HELPER METHODS FOR DEBUGGING THE GAMESOLVER
    def variablesOnBoard( target : Board ) = {
      boardNVariableToIntersection
        .map( { case ( (board, variable), intersection ) => if( board == target ) Some(variable) else None } )
        .flatten
    }

    def latestIntersection( board : Board, variable : AbstractVariable ) = {
      boardNVariableToIntersection.get((board, variable))
    }

    /**
     * Mapping from a board to the Intersection that represents the "this" literal.
     */
    val boardToSelfIntersection = new LinkedHashMap[Board, Intersection]

    val boardToSelfVariable = new LinkedHashMap[Board, Variable]


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

        val level = variablePosToLevel( cvar.varpos )
        val board = variablePosToBoard( cvar.varpos )

        cvar.varpos match {
          case recVp : ReceiverParameterVP =>
            //If the position == null then it is the top-level parameter class (otherwise it is a type
            //nested in a type parameter
            val isThis = Option( cvar.pos ).isEmpty
            val chute =  if( isThis ) createReceiverChute( cvar ) else createThisChute()

            val incoming = board.getIncomingNode()
            val connect = board.add(incoming, ReceiverInPort + genericsOffset( cvar ), Intersection.Kind.CONNECT, "input", chute)._2

            boardNVariableToIntersection += ( (board, cvar) -> connect )
            if( isThis ) {
              boardToSelfVariable  += (board -> cvar)
            }

          //WithinMethodVP cases
          case mvar : ParameterVP =>
            // For each parameter, create a CONNECT Intersection.
            // Also for FieldVP, but that's not an InMethodVP...
            val incoming = board.getIncomingNode
            val connect = board.add(incoming, ParamInPort + incoming.getOutputIDs().filter( _.startsWith( ParamInPort) ).size() + genericsOffset(cvar),
                                    CONNECT, "input", toChute(cvar))._2
            boardNVariableToIntersection += ((board, cvar) -> connect)

          case mvar: NewInMethodVP =>
            // For object creations, add a START_SMALL_BALL Intersection.
            val connect = board.add(START_SMALL_BALL, "output", CONNECT, "input", toChute(cvar))._2
            boardNVariableToIntersection += ( (board, cvar) -> connect )

          case mtp : MethodTypeParameterVP  =>
            //TODO: Is ordering going to be a problem?
            val incoming = board.getIncomingNode
            val connect = board.add(incoming, MethodTypeParamsInPort + genericsOffset(cvar),
              CONNECT, "input", toChute(cvar))._2
            boardNVariableToIntersection += ((board, cvar) -> connect)


          case mvar: WithinMethodVP =>
            // For returns, locals, casts, and instance-ofs, add a START_NO_BALL Intersections.  //TODO: Add refinement vars here?
            // TODO: Should a local variable start as BLACK/WHITE or NO ball?
            val connect = board.add(START_NO_BALL, "output", CONNECT, "input", toChute(cvar))._2
            boardNVariableToIntersection += ((board, cvar) -> connect)

          //WithinClassVP cases
          case clvar : FieldVP =>  {
            //If position is null then it is the "primary" annotation on a field
            //otherwise it is a type parameter (or an annotation contained within a type parameter)
            //these fields should be added as outputs/inputs to the subboard

            // For a field type, create three things.
            // 1. For field initializers, add the initial connects
            {
              val incoming = board.getIncomingNode
              val connect  = board.add(incoming, OutputPort+incoming.getOutputIDs().size(),  //TODO JB:  I think the port numbering is going to be off here
                                             CONNECT, "input", toChute(cvar))._2
              boardNVariableToIntersection += ((board, cvar) -> connect)
            }

            // 2. a field getter
            {
              // val getterBoard = newBoard(level, getFieldAccessorName(clvar.asInstanceOf[FieldVP]))
              val accessorBoardName = getFieldAccessorName(clvar)
              val getterBoard = findOrCreateMethodBoard(clvar, accessorBoardName )
              getterBoard.add(START_PIPE_DEPENDENT_BALL, "output", getterBoard.getOutgoingNode, ReturnOutPort + genericsOffset(cvar), toChute(cvar))


              if( !fieldBoardsToClass.keys.contains( accessorBoardName )) {
                fieldBoardsToClass += ( getterBoard -> clvar.getFQClassName )
              }
            }

            // 3. a field setter
            // Pass the receiver and it's type parameters (in this case the class's type parameters)
            // through the subboard but do NOT pass the field through, pass it in only
            {
              val setterName = getFieldSetterName( clvar )
              val setterBoard = findOrCreateMethodBoard(clvar, setterName)
              setterBoard.add(setterBoard.getIncomingNode, OutputPort + genericsOffset(cvar),
                              END, "input", toChute(cvar))

              if( !fieldBoardsToClass.keys.contains( setterName )) {
                fieldBoardsToClass += ( setterBoard -> clvar.getFQClassName )
              }
            }

          }

          case clVar: WithinClassVP if ( clVar.isInstanceOf[ClassTypeParameterVP]      ||
                                         clVar.isInstanceOf[ClassTypeParameterBoundVP] )  =>
            val connect = board.add(START_NO_BALL, "output", CONNECT, "input", toChute(cvar))._2
            boardNVariableToIntersection += ((board, cvar) -> connect)

            val typeVars =
              classToTypeParams.get( clVar.getFQClassName ).getOrElse({
                val typeVars = new java.util.ArrayList[AbstractVariable]()
                classToTypeParams += ( clVar.getFQClassName -> typeVars )
                typeVars
              })

            typeVars += cvar

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

      //Add all of the "receiver" type variables for fields (i.e. the class type variables for the class
      // in which the field is declared )
      fieldBoardsToClass.foreach( (boardToClassName : (Board, String )) => {
        classToTypeParams.get( boardToClassName._2 ).foreach( typeParams =>
          connectVariablesToInput( boardToClassName._1, typeParams.toList )
        )
      })

      //Add the type parameter lower bounds above subboard intersections that need them as input
      // (see addConstraintLowerBounds )
      constraints
        .filter( _.isInstanceOf[SubboardCallConstraint[_]] )
        .map(    _.asInstanceOf[SubboardCallConstraint[_]] )
        .foreach( addConstraintLowerBounds _ )

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

      //For ClassTypeParameterVPs and ClassTypeParameterBoundVPs the variable may be required in a sub-board
      //but because the
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
    val ParamOutPort    = "outParam"

    val ClassTypeParamsInPort  = "inClassTypeParam"
    val ClassTypeParamsOutPort = "outClassTypeParam"

    val MethodTypeParamsInPort  = "inMethodTypeParam"
    val MethodTypeParamsOutPort = "outMethodTypeParam"

    val ReceiverInPort  = "inReceiver"
    val ReceiverOutPort = "outReceiver"

    val OutputPort      = "output_"            //TODO: Standardize on a scheme
    val InputPort       = "input_"

    val ReturnOutPort   = "outputReturn"

  /*
     * Handles a constraint (adding necessary nodes and edges) for the given world.
     * Returns true if the constraint was successfully handled. Does not mutate and returns
     * false if the constraint was not successfully handled.
     */ 
    def handleConstraint(world: World, constraint: Constraint): Boolean = {
        constraint match {
          case comp: ComparableConstraint =>
            println("TODO: support comparable constraints!")

          case cc: CombineConstraint =>
            println("TODO: combine constraints should never happen!")

          case AssignmentConstraint(context, leftslot, rightslot) =>
            println("TODO: AssignmentConstraint not handled")

          case fac : FieldAccessConstraint     =>
            FieldAccessConstraintHandler( fac, this ).handle()

          case fac : FieldAssignmentConstraint =>
            FieldAssignmentConstraintHandler( fac, this ).handle()

          case instanceCall : InstanceMethodCallConstraint =>
            InstanceMethodCallConstraintHandler( instanceCall, this ).handle()

          case staticCall : StaticMethodCallConstraint =>
            StaticMethodCallConstraintHandler( staticCall, this ).handle()

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

      def connectToOutgoing( intersection : Intersection, board : Board, port : String, chute : Chute) = {
        val outgoing = board.getOutgoingNode()
        board.addEdge( intersection, "output", outgoing, port, chute)
      }

      val typeParamsToClass = CollectionUtil.reverseAndFlattenJList( classToTypeParams.toMap )

      // Connect all intersections to the corresponding outgoing slot
      // boardNVariableToIntersection foreach ( kv => { val ((board, cvar), lastsect) = kv
      boardNVariableToIntersection foreach { case ((board, cvar), lastIsect) => {

        cvar.varpos match {

          //Attach return types to outgoing ports
          case retVp : ReturnVP if variablePosToBoard(cvar.varpos) == board =>
            connectToOutgoing( lastIsect, board, ReturnOutPort + genericsOffset(cvar), toChute(cvar) )

          //If the class type parameter or its bound is in a method for its class then connect it to the outgoing port
          case ctpVp : ClassTypeParameterVP if typeParamsToClass( cvar ) == ctpVp.getFQClassName ||
                                               isGetterOrSetterReceiver(board, cvar )           =>
            connectToOutgoing( lastIsect, board, ClassTypeParamsOutPort + genericsOffset( cvar ), toChute(cvar) )

          case ctpVp : ClassTypeParameterBoundVP if typeParamsToClass( cvar ) == ctpVp.getFQClassName ||
                                               isGetterOrSetterReceiver(board, cvar )                =>
            connectToOutgoing( lastIsect, board, ClassTypeParamsOutPort + genericsOffset( cvar ), toChute(cvar)  )

          //If a method's type parameter or its bound is in the method for which it was defined connect it to the
          //outgoing port, we connect these through because lower bounds need to appear above method subboards
          //in which they take part because arguments to the method type parameters need to be subtypes of the
          // lower bound.  For upper bounds, the actual type argument flows through the upper bound's pipe
          case mtpVp : MethodTypeParameterVP if variablePosToBoard( mtpVp ) == board =>
            connectToOutgoing( lastIsect, board, MethodTypeParamsOutPort + genericsOffset( cvar ), toChute(cvar)  )

          case mtpVp : MethodTypeParameterVP if variablePosToBoard( mtpVp ) == board =>
            connectToOutgoing( lastIsect, board, MethodTypeParamsOutPort + genericsOffset( cvar ), toChute(cvar)  )

          // Pipe a methods receiver through
          case _ if isMethodReceiver( board, cvar ) =>
            connectToOutgoing( lastIsect, board, ReceiverOutPort + genericsOffset( cvar ), toChute(cvar)  )

          // Everything else simply gets terminated.
          case _ =>
            val end = board.add( lastIsect, "output", Intersection.Kind.END, "input", toChute(cvar) )._2
        }

      }}

      // Finally, deactivate all levels and add them to the world.
      classToLevel foreach { case (cname, level) =>
          level.finishConstruction()
          world.addLevel(cname, level)
      }
    }

    def findIntersection(board: Board, slot: Slot): Intersection

    //Used for the actual receiver object
    //E.g.
    // public void method( @HERE MyClass< @NOT_HERE String> this )
    def createThisChute() : Chute

    //Used for the type parameters that may be part of the receiver declaration
    //E.g.
    // public void method( @NOT_HERE MyClass< @HERE String> this )
    def createReceiverChute( variable : Variable ) : Chute

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


    def isBoardReceiver( board : Board, variable : AbstractVariable ) = {
      isGetterOrSetterReceiver( board, variable ) ||
      isMethodReceiver( board, variable )
    }

    //TODO: This will erroneously identify a ClassTypeParameterVP from outside the class
    //TODO: as a receiver param if it somehow ends up on that board
    def isGetterOrSetterReceiver( board : Board, variable : AbstractVariable ) = {
      ( isFieldGetterBoard( board ) || isFieldSetterBoard( board ) ) &&
        ( variable.varpos.isInstanceOf[ClassTypeParameterVP] ||
          variable.varpos.isInstanceOf[ClassTypeParameterBoundVP] )
    }

    def isMethodReceiver( board : Board, variable : AbstractVariable ) = {
      variable.varpos.isInstanceOf[ReceiverParameterVP]                                            &&
      methToBoard( variable.varpos.asInstanceOf[ReceiverParameterVP].getMethodSignature ) == board
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
            //addThisStart(b)
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
        //addThisStart(b)
        b
      }
    }

    /** Add the beginning of "this" pipes to a board. */
    /*def addThisStart(board: Board) {
      val incoming = board.getIncomingNode()
      val inthis = createThisChute()
      val connect = board.add(incoming, ReceiverInPort, Intersection.Kind.CONNECT, "input", inthis)._2
      boardToSelfIntersection += (board -> connect)
    } */

  /**
   * Add each variable in Variables as an input to the given board
   * @param board
   * @param variables
   */
    def connectVariablesToInput( board : Board, variables : List[AbstractVariable] ) {
      for( variable <- variables ) {
        val incoming = board.getIncomingNode()
        val chute = createChute(variable)
        val connect = board.add(incoming, (ReceiverInPort + genericsOffset(variable)),
                                Intersection.Kind.CONNECT, "input", chute)._2
        boardNVariableToIntersection += ((board, variable) -> connect )
      }

    }

  /**
   * Add each variable in Variables as an output of the given board.  The variables
   * must have been previously added to the given board
   * @param board
   * @param variables
   */
    def connectVariablesToOutput( board : Board, variables : List[AbstractVariable] ) {
      for( variable <- variables ) {
        val outgoing = board.getOutgoingNode()
        val chute = createChute( variable )
        val lastIsect = boardNVariableToIntersection((board, variable))
        board.addEdge(lastIsect, "output", outgoing,  (ReceiverInPort + genericsOffset(variable)), chute)
      }
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

    val GetterSuffix = "--GET"
    val SetterSuffix = "--SET"

    /**
     * Helper method to determine the name of the subboard used for a field getter.
     */
    def getFieldAccessorName(fvp: FieldVP): String = {
      fvp.getFQName + GetterSuffix
    }

    /**
     * Helper method to determine the name of the subboard used for a field setter.
     */
    def getFieldSetterName(fvp: FieldVP): String = {
      fvp.getFQName + SetterSuffix
    }

    def isFieldSetterName( name : String ) = name.endsWith( SetterSuffix )
    def isFieldGetterName( name : String ) = name.endsWith( GetterSuffix )

    def isFieldSetterBoard( board : Board ) = isFieldSetterName( board.getName() )
    def isFieldGetterBoard( board : Board ) = isFieldGetterName( board.getName() )

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
        avar.pos.zipWithIndex
          .map{ case (e, i) => math.pow(10, i).asInstanceOf[Int] * (e._1 + e._2 + 1) }
          .sum
      }
    }

  /**
   * For method invocations, the lower bounds of type variables are needed above the subboard
   * intersection that represents the inovcation.  For the given method call constraint
   * add these lower bounds to the board in which the method was called.  In the cases in
   * which a method is invoked in the class in which it is defined, or in a class in which a
   * previous method call for that class was already made then we do not have to add the
   * variables again.
   *
   * @param constraint
   */
  def addConstraintLowerBounds( constraint : SubboardCallConstraint[_] ) = {
    val contextVp = constraint.contextVp

    val board = variablePosToBoard( contextVp )
    val vars = ( constraint.classTypeParamLBs ++ constraint.methodTypeParamLBs )
                  .filterNot( isUniqueSlot _ )
                  .map( _.asInstanceOf[AbstractVariable] )

    vars.foreach( cvar => {
       if( !boardNVariableToIntersection.contains( (board, cvar) ) ) {
         val connect = board.add( START_PIPE_DEPENDENT_BALL, "output", CONNECT, "input", toChute( cvar ) )._2
         boardNVariableToIntersection += ( (board, cvar) -> connect )
       }
    })
  }
}