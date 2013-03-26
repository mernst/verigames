package games

import checkers.inference._
import checkers.util.AnnotationUtils
import scala.collection.mutable.HashMap
import scala.collection.mutable.LinkedHashMap
import com.sun.source.tree.Tree.Kind
import javax.lang.model.element.AnnotationMirror
import verigames.level._
import checkers.inference.LiteralNull
import checkers.inference.AbstractLiteral
import util.VGJavaConversions._
import scala.collection.mutable.Queue

/**
 * An abstract base class for all game solvers.
 */
abstract class GameSolver extends ConstraintSolver {

    /** All variables used in this program. */
    var variables: List[Variable] = null

    /** Empty, b/c there is no viewpoint adaptation (yet?). */
    var combvariables: List[CombVariable] = null

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
    val classToBoard = new LinkedHashMap[String, Board]

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
    constraints: List[Constraint],
    weights: List[WeightInfo],
    params: TTIRun): Option[Map[AbstractVariable, AnnotationMirror]] = {

      this.variables = variables
      this.combvariables = combvariables
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

      // First create all the levels and boards.
      createBoards(world)
      // Then represent all the constraints.
      handleConstraints(world)
      // Optimize the world, removing unnecessary complexity.
      optimizeWorld(world)
      // Finally, add any necessary plumbing to the end of each board.
      finalizeWorld(world)

      world
    }

    /**
     * First, go through all variables and create a level for each occurring
     * class and a board for each occurring method.
     */
    def createBoards(world: World) {
      variables foreach { cvar => {
        cvar.varpos match {
          case mvar: WithinMethodVP => {
            val level = variablePosToLevel(mvar)

            // Create/Find the board for the method.
            // val msig = mvar.getMethodSignature
            val board: Board = variablePosToBoard(mvar)

            if (mvar.isInstanceOf[ParameterVP]) {
              // For each parameter, create a CONNECT Intersection.
              // Also for FieldVP, but that's not a InMethodVP...
              val param = mvar.asInstanceOf[ParameterVP]
              val incoming = board.getIncomingNode()
              val start = Intersection.factory(Intersection.Kind.CONNECT)
              board.addNode(start)
              board.addEdge(incoming, ParamInPort+param.id, start, "input", new Chute(cvar.id, cvar.toString()))
              boardNVariableToIntersection += ((board, cvar) -> start)
            } else if (mvar.isInstanceOf[NewInMethodVP]) { 
              // For object creations, add a START_WHITE_BALL Intersection.
              val input = Intersection.factory(Intersection.Kind.START_SMALL_BALL)
              val start = Intersection.factory(Intersection.Kind.CONNECT)
              board.addNode(input)
              board.addNode(start)
              board.addEdge(input, "output", start, "input", new Chute(cvar.id, cvar.toString()))
              boardNVariableToIntersection += ((board, cvar) -> start)
            } else {
              // For returns, locals, casts, and instance-ofs, add a START_NO_BALL Intersections.
              // TODO: Should a local variable start as BLACK/WHITE or NO ball?
              val input = Intersection.factory(Intersection.Kind.START_NO_BALL)
              val start = Intersection.factory(Intersection.Kind.CONNECT)
              board.addNode(input)
              board.addNode(start)
              board.addEdge(input, "output", start, "input", new Chute(cvar.id, cvar.toString()))
              boardNVariableToIntersection += ((board, cvar) -> start)
            }
          }
          case clvar: WithinClassVP => {
            // Create/Find the level for the class.
            val level: Level = variablePosToLevel(clvar)

            // Create/Find the top-level board for the class.
            val board: Board = variablePosToBoard(clvar)

            if (clvar.isInstanceOf[FieldVP]) {
              // For a field type, create three things.
              // 1. For field initializers, add the initial connects
              {
                val incoming = board.getIncomingNode()
                val start = Intersection.factory(Intersection.Kind.CONNECT)
                board.addNode(start)
                board.addEdge(incoming, OutputPort+incoming.getOutputIDs().size(), start, "input", new Chute(cvar.id, cvar.toString()))
                boardNVariableToIntersection += ((board, cvar) -> start)
              }

              // 2. a field getter
              {
                // val getterBoard = newBoard(level, getFieldAccessorName(clvar.asInstanceOf[FieldVP]))
                val getterBoard = findOrCreateMethodBoard(clvar, getFieldAccessorName(clvar.asInstanceOf[FieldVP]))
                val inthis = findIntersection(getterBoard, LiteralThis)
                val outgoing = getterBoard.getOutgoingNode()
                val field = Intersection.factory(Intersection.Kind.START_PIPE_DEPENDENT_BALL)
                getterBoard.addNode(field)
                getterBoard.addEdge(field, "output", outgoing, ReturnOutPort, new Chute(cvar.id, cvar.toString()))
              }

              // 3. a field setter
              {
                // val setterBoard = newBoard(level, getFieldSetterName(clvar.asInstanceOf[FieldVP]))
                val setterBoard = findOrCreateMethodBoard(clvar, getFieldSetterName(clvar.asInstanceOf[FieldVP]))
                val inthis = findIntersection(setterBoard, LiteralThis)
                val incoming = setterBoard.getIncomingNode()
                val outgoing = setterBoard.getOutgoingNode()
                val field = Intersection.factory(Intersection.Kind.END)
                setterBoard.addNode(field)
                setterBoard.addEdge(incoming, OutputPort + (1 + genericsOffset(cvar)), field, "input", new Chute(cvar.id, cvar.toString()))
                // Let's not have an output for setters.
                // setterBoard.addEdge(field, 0, outgoing, 1, new Chute(cvar.id, cvar.toString()))
              }
            } else if (clvar.isInstanceOf[NewInFieldInitVP] ||
                clvar.isInstanceOf[NewInStaticInitVP]) {
              // For object creations, add a START_WHITE_BALL Intersection.
              val input = Intersection.factory(Intersection.Kind.START_SMALL_BALL)
              val start = Intersection.factory(Intersection.Kind.CONNECT)
              board.addNode(input)
              board.addNode(start)
              board.addEdge(input, "output", start, "input", new Chute(cvar.id, cvar.toString()))
              boardNVariableToIntersection += ((board, cvar) -> start)
            } else if (clvar.isInstanceOf[WithinFieldVP] ||
                clvar.isInstanceOf[WithinStaticInitVP]) {
              // For returns, locals, casts, and instance-ofs, add a START_NO_BALL Intersections.
              val input = Intersection.factory(Intersection.Kind.START_NO_BALL)
              val start = Intersection.factory(Intersection.Kind.CONNECT)
              board.addNode(input)
              board.addNode(start)
              board.addEdge(input, "output", start, "input", new Chute(cvar.id, cvar.toString()))
              boardNVariableToIntersection += ((board, cvar) -> start)
            } else {
              println("TODO: unsupported field variable position: " + cvar + " pos: " + cvar.varpos.getClass())
            }
          }
          case _ => {
            println("TODO: unhandled position for: " + cvar + " pos: " + cvar.varpos.getClass())
          }
        }
      }}
    }


    /**
     * Go through all constraints and add the corresponding piping to the boards.
     */
    def handleConstraints(world: World) {
      var workQueue = new Queue[Constraint]
      constraints foreach { constraint => {
        workQueue += constraint
      }}
      while (!workQueue.isEmpty) {
        val initialSize = workQueue.size
        var i = 0
        for (i <- 1 to initialSize) {
          val constraint = workQueue.dequeue
          if (!handleConstraint(world, constraint)) {
            workQueue += constraint
          }
        }
        if (workQueue.size == initialSize) {
          throw new IllegalStateException("Constraints not solvable: " + workQueue)
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
        constraint match {
          case comp: ComparableConstraint => {
            println("TODO: support comparable constraints!")
          }
          case cc: CombineConstraint => {
            println("TODO: combine constraints should never happen!")
          }
          case FieldAccessConstraint(context, receiver, fieldslot, fieldvp) => {
            val ctxBoard = variablePosToBoard(context)
            val subboard = newSubboard(ctxBoard, fieldvp, getFieldAccessorName(fieldvp))

            { // Connect the receiver to input and output 0
              val receiverInt = findIntersection(ctxBoard, receiver)

              ctxBoard.addEdge(receiverInt, "output", subboard, ReceiverInPort, createChute(receiver))

              val con = Intersection.factory(Intersection.Kind.CONNECT)
              ctxBoard.addNode(con)
              ctxBoard.addEdge(subboard, ReceiverOutPort, con, "input", createChute(receiver))

              updateIntersection(ctxBoard, receiver, con)
            }
            { // Connect the result as output only
              fieldslot match {
                case fieldvar: Variable => {
                  if (boardNVariableToIntersection.contains((ctxBoard, fieldvar))) {
                    // Field was previously accessed.
                    val fieldInt = boardNVariableToIntersection((ctxBoard, fieldvar))
                    val merge = Intersection.factory(Intersection.Kind.MERGE)
                    ctxBoard.addNode(merge)
                    ctxBoard.addEdge(subboard, ReturnOutPort, merge, "left", new Chute(fieldvar.id, fieldvar.toString()))
                    ctxBoard.addEdge(fieldInt, "output", merge, "right", new Chute(fieldvar.id, fieldvar.toString()))
                    boardNVariableToIntersection.update((ctxBoard, fieldvar), merge)
                  } else {
                    val con = Intersection.factory(Intersection.Kind.CONNECT)
                    ctxBoard.addNode(con)
                    ctxBoard.addEdge(subboard, ReturnOutPort, con, "input", new Chute(fieldvar.id, fieldvar.toString()))
                    boardNVariableToIntersection.update((ctxBoard, fieldvar), con)
                  }
                }
                case _ => {
                  println("Unhandled field type slot! " + fieldslot)
                }
              }
            }
          }
          case FieldAssignmentConstraint(context, recvslot, fieldslot, rightslot) => {
            val ctxBoard = variablePosToBoard(context)
            fieldslot match {
              case fieldvar : Variable => {
                fieldvar.varpos match {
                  case fvp: FieldVP => {
                    val subboard = newSubboard(ctxBoard, fvp, getFieldSetterName(fvp))
                    val recvInt = findIntersection(ctxBoard, recvslot)
                    ctxBoard.addEdge(recvInt, "output", subboard, ReceiverInPort, createChute(recvslot))

                    if (isUniqueSlot(rightslot)) {
                      val rightInt = findIntersection(ctxBoard, rightslot)
                      ctxBoard.addEdge(rightInt, "output", subboard, OutputPort + (1 + genericsOffset(fieldvar)), createChute(rightslot))
                    } else {
                      val rightInt = findIntersection(ctxBoard, rightslot)
                      val split = Intersection.factory(Intersection.Kind.SPLIT)
                      ctxBoard.addNode(split)

                      ctxBoard.addEdge(rightInt, "output", split, "input", createChute(rightslot))
                      ctxBoard.addEdge(split, "split", subboard, OutputPort + (1 + genericsOffset(fieldvar)), createChute(rightslot))

                      updateIntersection(ctxBoard, rightslot, split)
                    }

                    val con = Intersection.factory(Intersection.Kind.CONNECT)
                    ctxBoard.addNode(con)
                    ctxBoard.addEdge(subboard, ReceiverOutPort, con, "input", createChute(recvslot))

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
          }
          case AssignmentConstraint(context, leftslot, rightslot) => {
            println("TODO: AssignmentConstraint not handled")
          }
          case CallInstanceMethodConstraint(caller, receiver, methname, tyargs, args, result) => {
            val callerBoard = variablePosToBoard(caller)
            val subboard = newSubboard(callerBoard, methname, methname.getMethodSignature)
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
                case None => outputMap.update(slot, List(intersection))
              }
            }

            { // Connect the receiver to input and output 0
              val receiverIntersection = localFindIntersection(receiver)

              // split so that if the argument is aliased, we have something
              // above the subboard to connect to.
              val split = Intersection.factory(Intersection.Kind.SPLIT)
              callerBoard.addNode(split)
              callerBoard.addEdge(receiverIntersection, "toSplit", split, "input", createChute(receiver))
              callerBoard.addEdge(split, "toSubboard", subboard, ReceiverInPort, createChute(receiver))
              localIntersectionMap.update(receiver, split)

              // pipe the receiver through the subboard
              val connect = Intersection.factory(Intersection.Kind.CONNECT)
              callerBoard.addNode(connect)
              callerBoard.addEdge(subboard, ReceiverOutPort, connect, "input", createChute(receiver))

              addToOutputMap(receiver, connect)
            }
            { // TODO: type arguments
            }
            { // Connect the arguments as inputs only
              for (anarg <- args) {
                println(anarg)
                // TODO: merge this with RHS of assignment
                if (isUniqueSlot(anarg)) {
                  val anargInt = localFindIntersection(anarg)
                  callerBoard.addEdge(anargInt, "output", subboard, ParamInPort + subboardPort, createChute(anarg))
                } else {
                  val anargInt = localFindIntersection(anarg)

                  val split = Intersection.factory(Intersection.Kind.SPLIT)
                  callerBoard.addNode(split)

                  callerBoard.addEdge(anargInt, "output", split, "input", createChute(anarg))
                  callerBoard.addEdge(split, "split", subboard, ParamInPort + subboardPort, createChute(anarg))

                  // it's a bit of a hack to update both the local and the
                  // global intersection maps, but it won't be necessary once
                  // all arguments are piped through
                  localIntersectionMap.update(anarg, split)
                  updateIntersection(callerBoard, anarg, split)
                }
                subboardPort += 1
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
              val end = Intersection.factory(Intersection.Kind.END)
              callerBoard.addNode(end)
              callerBoard.addEdge(receiverSplit, "toEnd", end, "input", createChute(receiver))

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
                  val mergeIntersection = Intersection.factory(Intersection.Kind.MERGE)
                  callerBoard.addNode(mergeIntersection)
                  callerBoard.addEdge(first, "toMerge", mergeIntersection, "first", chuteFactory())
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
            { // Connect the result as output only
              result match {
                case resvar: Variable => {
                  if (boardNVariableToIntersection.contains((callerBoard, resvar))) {
                    // Method was previously called.
                    val resInt = boardNVariableToIntersection((callerBoard, resvar))
                    val merge = Intersection.factory(Intersection.Kind.MERGE)
                    callerBoard.addNode(merge)
                    callerBoard.addEdge(subboard, ReturnOutPort, merge, "left", new Chute(resvar.id, resvar.toString()))
                    callerBoard.addEdge(resInt, "output", merge, "right", new Chute(resvar.id, resvar.toString()))
                    boardNVariableToIntersection.update((callerBoard, resvar), merge)
                  } else {
                    val con = Intersection.factory(Intersection.Kind.CONNECT)
                    callerBoard.addNode(con)
                    callerBoard.addEdge(subboard, ReturnOutPort, con, "input", new Chute(resvar.id, resvar.toString()))
                    boardNVariableToIntersection.update((callerBoard, resvar), con)
                  }
                }
                case _ => {
                  // Nothing to do for void methods.
                  // TODO: this is also for pre-annotated return types!
                  // println("Unhandled return type slot! " + result)
                }
              }
            }
          }
          case _ => {
            // Don't do anything here and hope the subclass does something.
          }
        }
        return true
    }

    /**
     * Type-system independent optimizations of the world.
     */
    def optimizeWorld(world: World) {/*
      import scala.collection.JavaConversions._

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
        if (cvar.varpos.isInstanceOf[ReturnVP]) {
          // Only the return variable is attached to outgoing.
          val outgoing = board.getOutgoingNode()
          board.addEdge(lastsect, "output", outgoing, ReturnOutPort, new Chute(cvar.id, cvar.toString()))
        } else {
          // Everything else simply gets terminated.
          val end = Intersection.factory(Intersection.Kind.END)
          board.addNode(end)
          board.addEdge(lastsect, "output", end, "input", new Chute(cvar.id, cvar.toString()))
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
      val b = new Board()
      // println("created board " + b + " with name " + name)
      val cleanname = cleanUpForXML(name)
      level.addBoard(cleanname, b)

      b.addNode(Intersection.factory(Intersection.Kind.INCOMING))
      b.addNode(Intersection.factory(Intersection.Kind.OUTGOING))

      b
    }

    /**
     * Create a new subboard on callerBoard.
     */
    def newSubboard(callerBoard: Board, calledvarpos: VariablePosition, calledname: String): Subboard = {
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
      val start = Intersection.factory(Intersection.Kind.CONNECT)
      board.addNode(start)
      val inthis = createThisChute()
      board.addEdge(incoming, ReceiverInPort, start, "input", inthis)
      boardToSelfIntersection += (board -> start)
    }

    /**
     * Find the board that should be used for a constraint between two
     * slots.
     */
    def findBoard(slot1: Slot, slot2: Slot): Board = {
      (slot1, slot2) match {
        case (cvar1: Variable, cvar2: Variable) => {
          val board1 = variablePosToBoard(cvar1.varpos)
          val board2 = variablePosToBoard(cvar2.varpos)

          if (board1==board2) {
            board1
          } else if (cvar1.varpos.isInstanceOf[ReturnVP]) {
             board2
          } else if (cvar2.varpos.isInstanceOf[ReturnVP]) {
            board2
          } else {
            /* We only need to handle variables that will end up on the same board.
             * For all other variables, there will be a MethodCall, FieldRead, or FieldUpdate
             * constraint, that links things together.
             */
            null
          }
        }

        case (cvar1: Variable, lit: AbstractLiteral) => {
          if (cvar1.varpos.isInstanceOf[ParameterVP]) {
            null
          } else {
            variablePosToBoard(cvar1.varpos)
          }
        }
        case (lit: AbstractLiteral, cvar2: Variable) => {
          if (cvar2.varpos.isInstanceOf[ParameterVP]) {
            null
          } else {
            variablePosToBoard(cvar2.varpos)
          }
        }
        case (cvar1: Variable, c: Constant) => {
          variablePosToBoard(cvar1.varpos)
        }
        case (c: Constant, cvar2: Variable) => {
          variablePosToBoard(cvar2.varpos)
        }
        case (cv: CombVariable, cvar2: Variable) => {
          // TODO: Combvariables appear for BinaryTrees.
          variablePosToBoard(cvar2.varpos)
        }
        case (_, _) => {
          println("TODO: findBoard unhandled slots: " + slot1 + " and " + slot2)
          null
        }
      }
    }

    /**
     * Sanitize a string to make it a suitable XML identifier.
     */
    def cleanUpForXML(name: String): String = {
      name.replace('(', '-')
        .replace(')', '-')
        .replace(':', '-')
        .replace('#', '-')
        .replace(';', '-')
        .replace('/', '-')
        // Constructors are named "<init>" and "<cinit>"
        .replace('<', '-')
        .replace('>', '-')
        // Arrays in bytecode
        .replace('[', '-')
    }

    /** For "unique" slots we do not need to create splits, as a new, unique
     * intersection is generated each time.
     */
    def isUniqueSlot(slot: Slot): Boolean = {
      !(slot.isInstanceOf[Variable] || slot == LiteralThis)
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