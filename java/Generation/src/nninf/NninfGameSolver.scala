package nninf

import checkers.inference._
import checkers.inference.pbssolver._
import checkers.util.AnnotationUtils
import scala.collection.mutable.HashMap
import com.sun.source.tree.Tree.Kind
import javax.lang.model.element.AnnotationMirror
import verigames.level._

class NninfGameSolver(
    /** All variables used in this program. */
    variables: List[Variable],
    /** Empty, b/c there is no viewpoint adaptation (yet?). */
    combvariables: List[CombVariable],
    /** All constraints that have to be fulfilled. */
    constraints: List[Constraint],
    /** Weighting information. Currently empty & ignored, as a human solves the game. */
    weights: List[WeightInfo],
    /** The command-line parameters. */
    params: TTIRun)
  extends ConstraintSolver(variables, combvariables, constraints, weights, params) {

    // TODO: ensure that no CombVariables were created
    // assert combvariables.length == 0

    def solve(): Option[Map[AbstractVariable, AnnotationMirror]] = {
      // Create the world!
      val world = createWorld()

      // Assign a layout to the world.
      verigames.layout.WorldLayout.layout(world)

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
     * We generate a separate level for every class.
     * The key is the fully-qualified class name and the
     * value is the corresponding level.
     */
    val classToLevel = new HashMap[String, Level]

    /**
     * We generate one board for every class that contains the field
     * initializers (other top-level things?).
     * The key is the fully-qualified class name and the
     * value is the corresponding board.
     */
    val classToBoard = new HashMap[String, Board]

    /** We generate a separate board for every method within a class.
     * The key is the fully-qualified class name followed by the method
     * signature and the value is the corresponding board.
     */
    val methToBoard = new HashMap[String, Board]

    /**
     * For each constraint variable we keep a reference to the
     * Intersection that should be used as next input.
     * For local slots that would be unique enough; however, fields and
     * method parameters/returns occur on multiple boards. Therefore,
     * the key in the map is a pair of Board and Variable.
     * Output port 0 of the Intersection has to be free.
     */
    val boardNVariableToIntersection = new HashMap[(Board, AbstractVariable), Intersection]

    /**
     * Mapping from a board to the Intersection that represents the "this" literal.
     */
    val boardToSelfIntersection = new HashMap[Board, Intersection]

    /**
     * First, go through all variables and create a level for each occurring
     * class and a board for each occurring method.
     */
    def createBoards(world: World) { 
      variables foreach { cvar => {
        cvar.varpos match {
          case mvar: WithinMethodVP => {
            val fqcname = mvar.getFQClassName
            // Create/Find the level for the class.
            val level: Level = if (classToLevel.contains(fqcname)) {
                classToLevel(fqcname)
              } else {
                val l = new Level
                classToLevel += (fqcname -> l)
                l
              }

            // Create/Find the board for the method.
            val msig = mvar.getMethodSignature
            val board: Board = if (methToBoard.contains(msig)) {
                methToBoard(msig)
              } else {
                val b = newBoard(level, msig)
                methToBoard += (msig -> b)
                // TODO: handle static methods
                // For each method, create an input and output for the implicit "this".
                val incoming = b.getIncomingNode()
                val start = Intersection.factory(Intersection.Kind.CONNECT)
                b.addNode(start)
                val inthis = new Chute(-1, "this")
                inthis.setEditable(false)
                b.addEdge(incoming, incoming.getOutputs().size(), start, 0, inthis)
                boardToSelfIntersection += (b -> start)
                b
              }

            if (mvar.isInstanceOf[ParameterVP]) {
              // For each parameter, create a CONNECT Intersection.
              // Also for FieldVP, but that's not a InMethodVP...
              val incoming = board.getIncomingNode()
              val start = Intersection.factory(Intersection.Kind.CONNECT)
              board.addNode(start)
              board.addEdge(incoming, incoming.getOutputs().size(), start, 0, new Chute(cvar.id, cvar.toString()))
              boardNVariableToIntersection += ((board, cvar) -> start)
            } else if (mvar.isInstanceOf[NewInMethodVP]) {
              // For object creations, add a START_WHITE_BALL Intersection.
              val input = Intersection.factory(Intersection.Kind.START_WHITE_BALL)
              val start = Intersection.factory(Intersection.Kind.CONNECT)
              board.addNode(input)
              board.addNode(start)
              board.addEdge(input, 0, start, 0, new Chute(cvar.id, cvar.toString()))
              boardNVariableToIntersection += ((board, cvar) -> start)
            } else {
              // For returns, locals, casts, and instance-ofs, add a START_NO_BALL Intersections.
              // TODO: Should a local variable start as BLACK/WHITE or NO ball?
              val input = Intersection.factory(Intersection.Kind.START_NO_BALL)
              val start = Intersection.factory(Intersection.Kind.CONNECT)
              board.addNode(input)
              board.addNode(start)
              board.addEdge(input, 0, start, 0, new Chute(cvar.id, cvar.toString()))
              boardNVariableToIntersection += ((board, cvar) -> start)
            }
          }
          case clvar: WithinClassVP => {
            val fqcname = clvar.getFQClassName
            // Create/Find the level for the class.
            val level: Level = if (classToLevel.contains(fqcname)) {
                classToLevel(fqcname)
              } else {
                val l = new Level
                classToLevel += (fqcname -> l)
                l
              }

            // Create/Find the top-level board for the class.
            val board: Board = if (classToBoard.contains(fqcname)) {
                classToBoard(fqcname)
              } else {
                val b = newBoard(level, fqcname)
                classToBoard += (fqcname -> b)
                b
              }

            if (clvar.isInstanceOf[FieldVP]) {
              // In the field type, just add a CONNECT Intersection.
              val incoming = board.getIncomingNode()
              val start = Intersection.factory(Intersection.Kind.CONNECT)
              board.addNode(start)
              board.addEdge(incoming, incoming.getOutputs().size(), start, 0, new Chute(cvar.id, cvar.toString()))
              boardNVariableToIntersection += ((board, cvar) -> start)
            } else if (clvar.isInstanceOf[NewInFieldInitVP] ||
                clvar.isInstanceOf[NewInStaticInitVP]) {
              // For object creations, add a START_WHITE_BALL Intersection.
              val input = Intersection.factory(Intersection.Kind.START_WHITE_BALL)
              val start = Intersection.factory(Intersection.Kind.CONNECT)
              board.addNode(input)
              board.addNode(start)
              board.addEdge(input, 0, start, 0, new Chute(cvar.id, cvar.toString()))
              boardNVariableToIntersection += ((board, cvar) -> start)
            } else if (clvar.isInstanceOf[WithinFieldVP] ||
                clvar.isInstanceOf[WithinStaticInitVP]) {
              // For returns, locals, casts, and instance-ofs, add a START_NO_BALL Intersections.
              val input = Intersection.factory(Intersection.Kind.START_NO_BALL)
              val start = Intersection.factory(Intersection.Kind.CONNECT)
              board.addNode(input)
              board.addNode(start)
              board.addEdge(input, 0, start, 0, new Chute(cvar.id, cvar.toString()))
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
      constraints foreach { constraint => {
        constraint match {
          case SubtypeConstraint(sub, sup) => {
            // No need to generate something for trivial super/sub-types.
            if (sup != NninfConstants.NULLABLE &&
                sub != NninfConstants.NONNULL) {

              if (sub == LiteralNull) {
                // For "null <: sup" create a black ball falling into sup.
                // println("null <: " + sup)

                // Assume sup is a variable. Alternatives?
                val supvar = sup.asInstanceOf[Variable]
                val board = variablePosToBoard(supvar.varpos)
                val blackball = Intersection.factory(Intersection.Kind.START_BLACK_BALL)
                val merge = Intersection.factory(Intersection.Kind.MERGE)
                val lastIntersection = boardNVariableToIntersection((board, supvar))

                board.addNode(blackball)
                board.addNode(merge)

                board.addEdge(lastIntersection, 0, merge, 0, new Chute(supvar.id, supvar.toString()))
                board.addEdge(blackball, 0, merge, 1, new Chute(-1, "null literal"))

                boardNVariableToIntersection.update((board, supvar), merge)
              } else {
                // Subtypes between arbitrary variables only happens for local variables.
                // TODO: what happens for "x = o.f"? Do I always create ASSIGNMENT constraints?
                // What about m(o.f)?
                val board = findBoard(sub, sup)

                val subID = findSlotID(sub)
                val subDesc = findSlotDesc(sub)
                val supID = findSlotID(sup)
                val supDesc = findSlotDesc(sup)

                if (board!=null) {
                  // println(sub + " <: " + sup)

                  val merge = Intersection.factory(Intersection.Kind.MERGE)
                  val split = Intersection.factory(Intersection.Kind.SPLIT)
                  val sublast = findIntersection(board, sub)
                  val suplast = findIntersection(board, sup)

                  board.addNode(merge)
                  board.addNode(split)

                  // TODO: which variable get's the merge output??
                  board.addEdge(sublast, 0, split, 0, new Chute(subID, subDesc))
                  board.addEdge(suplast, 0, merge, 0, new Chute(supID, supDesc))
                  board.addEdge(split, 1, merge, 1, new Chute(subID, subDesc))

                  updateIntersection(board, sub, split)
                  updateIntersection(board, sup, merge)
                }
              }
            }
          }
          case EqualityConstraint(ell, elr) => {
            println("TODO: " + ell + " == " + elr + " not supported yet!")
          }
          case InequalityConstraint(ell, elr) => {
            // println(ell + " != " + elr)
            // TODO: support var!=NULLABLE for now
            if (elr == NninfConstants.NULLABLE) {
              val ellvar = ell.asInstanceOf[Variable]
              val board = variablePosToBoard(ellvar.varpos);

              val con = Intersection.factory(Intersection.Kind.CONNECT)
              val elllast = boardNVariableToIntersection((board, ellvar))

              board.addNode(con)

              val chute = new Chute(ellvar.id, ellvar.toString())
              chute.setNarrow(true)
              chute.setEditable(false)

              board.addEdge(elllast, 0, con, 0, chute)

              boardNVariableToIntersection.update((board, ellvar), con)
            } else {
              println("TODO: uncovered inequality case!")
            }
          }
          case comp: ComparableConstraint => {
            println("TODO: support comparable constraints!")
          }
          case cc: CombineConstraint => {
            println("TODO: combine constraints should never happen!")
          }
          case CallInstanceMethodConstraint(caller, receiver, methname, tyargs, args, result) => {
            val callerBoard = variablePosToBoard(caller)
            val subboard = newSubboard(callerBoard, methname)
            // The input port to use next
            var subboardPort = 0

            { // Connect the receiver to input and output 0
              val receiverInt = findIntersection(callerBoard, receiver)
              val receiverID = findSlotID(receiver)
              val receiverDesc = findSlotDesc(receiver)

              callerBoard.addEdge(receiverInt, 0, subboard, 0, new Chute(receiverID, receiverDesc))

              val con = Intersection.factory(Intersection.Kind.CONNECT)
              callerBoard.addNode(con)
              callerBoard.addEdge(subboard, 0, con, 0, new Chute(receiverID, receiverDesc))
              
              updateIntersection(callerBoard, receiver, con)
            }
            { // TODO: type arguments
            }
            { // Connect the arguments as inputs only 
              for (anarg <- args) {
                subboardPort += 1
                val anargInt = findIntersection(callerBoard, anarg)
                val anargID = findSlotID(anarg)
                val anargDesc = findSlotDesc(anarg)

                val split = Intersection.factory(Intersection.Kind.SPLIT)

                callerBoard.addNode(split)

                callerBoard.addEdge(anargInt, 0, split, 0, new Chute(anargID, anargDesc))
                callerBoard.addEdge(split, 1, subboard, subboardPort, new Chute(anargID, anargDesc))

                updateIntersection(callerBoard, anarg, split)
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
                    callerBoard.addEdge(subboard, 1, merge, 0, new Chute(resvar.id, resvar.toString()))
                    callerBoard.addEdge(resInt, 0, merge, 1, new Chute(resvar.id, resvar.toString()))
                    boardNVariableToIntersection.update((callerBoard, resvar), merge)
                  } else {
                    val con = Intersection.factory(Intersection.Kind.CONNECT)
                    callerBoard.addNode(con)
                    callerBoard.addEdge(subboard, 1, con, 0, new Chute(resvar.id, resvar.toString()))
                    boardNVariableToIntersection.update((callerBoard, resvar), con)
                  }
                }
                case _ => {
                  // Nothing to do for void methods.
                  // TODO: this is also for pre-annotated return types!
                }
              }
            }
          }
        }
      }}
    }

    /**
     * Finalize the world by closing the scope of all variables and adding
     * the necessary edges to the output.
     */
    def finalizeWorld(world: World) {
      // Connect all intersections to the corresponding outgoing slot
      boardNVariableToIntersection foreach ( kv => { val ((board, cvar), lastsect) = kv
        if (cvar.varpos.isInstanceOf[ReturnVP]) {
          // Only the return variable is attached to outgoing.
          val outgoing = board.getOutgoingNode()
          board.addEdge(lastsect, 0, outgoing, outgoing.getInputs().size(), new Chute(cvar.id, cvar.toString()))        
        } else {
          // Everything else simply gets terminated.
          val end = Intersection.factory(Intersection.Kind.END)
          board.addNode(end)
          board.addEdge(lastsect, 0, end, 0, new Chute(cvar.id, cvar.toString()))
        }
      })

      boardToSelfIntersection foreach ( kv => { val (board, lastsect) = kv
        val outgoing = board.getOutgoingNode()
        val outthis = new Chute(-1, "this")
        outthis.setEditable(false)
        board.addEdge(lastsect, 0, outgoing, outgoing.getInputs().size(), outthis)
      })

      // Finally, deactivate all levels and add them to the world.
      // The first line must be doable somehow nicer.
      classToLevel foreach ( kv => { val (cname, level) = kv
          level.finishConstruction()
          world.addLevel(cname, level)
      })
    }

    /**
     * Create a new board within the given level.
     * Sanitizes the name to be a valid XML ID.
     */
    def newBoard(level: Level, name: String): Board = {
      val b = new Board()
      val cleanname = cleanUpForXML(name)
      level.addBoard(cleanname, b)
      
      b.addNode(Intersection.factory(Intersection.Kind.INCOMING))
      b.addNode(Intersection.factory(Intersection.Kind.OUTGOING))
      
      b
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
    }

    /**
     * Create a new subboard on callerBoard.
     */
    def newSubboard(callerBoard: Board, called: CalledMethodVP): Subnetwork = {
      val subboard = Intersection.subnetworkFactory(cleanUpForXML(called.getMethodSignature))
      callerBoard.addNode(subboard)
      subboard
    }

    /**
     * Look up the board for a given variable position.
     */
    def variablePosToBoard(varpos: VariablePosition): Board = {
      varpos match {
        case mvar: WithinMethodVP => {
          methToBoard(mvar.getMethodSignature)
        }
        case clvar: WithinClassVP => {
          classToBoard(clvar.getFQClassName)
        }
        case _ => {
          println("variablePosToBoard: unhandled position: " + varpos)
          null
        }
      }
    }

    /**
     * Find the board that should be used for a constraint between two
     * variables.
     * 
     */
    def findBoard(slot1: Slot, slot2: Slot): Board = {
      (slot1, slot2) match {
        case (cvar1: Variable, cvar2: Variable) => {
          val board1 = variablePosToBoard(cvar1.varpos)
          val board2 = variablePosToBoard(cvar2.varpos)

          if (board1==board2) {
            board1
          } else {
            /* We only need to handle variables that will end up on the same board.
             * For all other variables, there will be a MethodCall, FieldRead, or FieldUpdate
             * constraint, that links things together.
             */
            null
          }
        }
        case (cvar1: Variable, LiteralThis) => {
          if (cvar1.varpos.isInstanceOf[ParameterVP]) {
            null
          } else {
            variablePosToBoard(cvar1.varpos)
          }
        }
        case (LiteralThis, cvar2: Variable) => {
          if (cvar2.varpos.isInstanceOf[ParameterVP]) {
            null
          } else {
            variablePosToBoard(cvar2.varpos)
          }
        }
      }
    }

    def findIntersection(board: Board, slot: Slot): Intersection = {
      slot match {
        case v: Variable =>
          boardNVariableToIntersection((board, v))
        case LiteralThis =>
          boardToSelfIntersection(board)
        case _ => {
          println("findIntersection: unmatched slot: " + slot)
          null
        }
      }
    }

    def updateIntersection(board: Board, slot: Slot, inters: Intersection) {
      slot match {
        case v: Variable =>
          boardNVariableToIntersection.update((board, v), inters)
        case LiteralThis =>
          boardToSelfIntersection.update(board, inters)
        case _ => {
          println("updateIntersection: unmatched slot: " + slot)
        }
      }
    }

    def findSlotID(slot: Slot): Int = {
      slot match {
        case v: Variable =>
          v.id
        case LiteralThis =>
          -1
        case _ => {
          println("findSlotID: unmatched slot: " + slot)
          -666
        }
      }
    }

    def findSlotDesc(slot: Slot): String = {
      slot match {
        case v: Variable =>
          v.toString()
        case LiteralThis =>
          "this"
        case _ => {
          println("findSlotDesc: unmatched slot: " + slot)
          null
        }
      }
    }

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
}