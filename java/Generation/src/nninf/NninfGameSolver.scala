package nninf

import checkers.inference._
import checkers.util.AnnotationUtils
import scala.collection.mutable.HashMap
import com.sun.source.tree.Tree.Kind
import javax.lang.model.element.AnnotationMirror
import verigames.level._
import checkers.inference.LiteralNull
import checkers.inference.AbstractLiteral

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
            val level = variablePosToLevel(mvar)

            // Create/Find the board for the method.
            // val msig = mvar.getMethodSignature
            val board: Board = variablePosToBoard(mvar) 

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
                board.addEdge(incoming, incoming.getOutputs().size(), start, 0, new Chute(cvar.id, cvar.toString()))
                boardNVariableToIntersection += ((board, cvar) -> start)
              }

              // 2. a field getter
              {
                // val getterBoard = newBoard(level, getFieldAccessorName(clvar.asInstanceOf[FieldVP]))
                val getterBoard = findOrCreateMethodBoard(clvar, getFieldAccessorName(clvar.asInstanceOf[FieldVP]))
                val inthis = findIntersection(getterBoard, LiteralThis)
                val outgoing = getterBoard.getOutgoingNode()
                val field = Intersection.factory(Intersection.Kind.START_WHITE_BALL)
                getterBoard.addNode(field)
                getterBoard.addEdge(field, 0, outgoing, 1 + genericsOffset(cvar), new Chute(cvar.id, cvar.toString()))
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
                setterBoard.addEdge(incoming, 1 + genericsOffset(cvar), field, 0, new Chute(cvar.id, cvar.toString()))
                // Let's not have an output for setters.
                // setterBoard.addEdge(field, 0, outgoing, 1, new Chute(cvar.id, cvar.toString()))
              }
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

                if (board!=null) {
                  // println(sub + " <: " + sup)

                  val merge = Intersection.factory(Intersection.Kind.MERGE)
                  board.addNode(merge)
                  val sublast = findIntersection(board, sub)
                  val suplast = findIntersection(board, sup)

                  if (isUniqueSlot(sub)) {
                    board.addEdge(sublast, 0, merge, 1, createChute(sub))
                    board.addEdge(suplast, 0, merge, 0, createChute(sup))

                    updateIntersection(board, sup, merge)
                  } else if (isUniqueSlot(sup)) {
                    board.addEdge(sublast, 0, merge, 1, createChute(sub))
                    board.addEdge(suplast, 0, merge, 0, createChute(sup))

                    updateIntersection(board, sub, merge)
                  } else {
                    val split = Intersection.factory(Intersection.Kind.SPLIT)
                    board.addNode(split)

                    board.addEdge(sublast, 0, split, 0, createChute(sub))
                    board.addEdge(suplast, 0, merge, 0, createChute(sup))
                    board.addEdge(split, 1, merge, 1, createChute(sub))

                    updateIntersection(board, sub, split)
                    updateIntersection(board, sup, merge)
                  }
                  
                  if (sup.isInstanceOf[Variable] &&
                      sup.asInstanceOf[Variable].varpos.isInstanceOf[ReturnVP]) {
                    val supvar = sup.asInstanceOf[Variable]
                    val outgoing = board.getOutgoingNode()
                    val prevout = outgoing.getInput(1)
                    if (prevout==null) {
                        board.addEdge(merge, 0, outgoing, 1, new Chute(supvar.id, supvar.toString()))
                        // The variable is already connected to the end, nothing more to do
                        boardNVariableToIntersection.remove((board, supvar))
                    } else {
                      println("Heeeyy!")
                    }
                  }
                }
              }
            }
          }
          case EqualityConstraint(ell, elr) => {
            println("TODO: " + ell + " == " + elr + " not supported yet!")
          }
          case InequalityConstraint(ctx, ell, elr) => {
            // println(ell + " != " + elr)
            // TODO: support var!=NULLABLE for now
            if (elr == NninfConstants.NULLABLE) {
              val ellvar = ell.asInstanceOf[Variable]
              val board = variablePosToBoard(ctx);

              val con = Intersection.factory(Intersection.Kind.CONNECT)
              board.addNode(con)

              val chute = new Chute(ellvar.id, ellvar.toString())
              chute.setPinched(true)

              val elllast = findIntersection(board, ellvar)

              board.addEdge(elllast, 0, con, 0, chute)

              updateIntersection(board, ellvar, con)
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
          case FieldAccessConstraint(context, receiver, fieldslot, fieldvp) => {
            val ctxBoard = variablePosToBoard(context)
            val subboard = newSubboard(ctxBoard, fieldvp, getFieldAccessorName(fieldvp))

            { // Connect the receiver to input and output 0
              val receiverInt = findIntersection(ctxBoard, receiver)

              ctxBoard.addEdge(receiverInt, 0, subboard, 0, createChute(receiver))

              val con = Intersection.factory(Intersection.Kind.CONNECT)
              ctxBoard.addNode(con)
              ctxBoard.addEdge(subboard, 0, con, 0, createChute(receiver))
              
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
                    ctxBoard.addEdge(subboard, 1, merge, 0, new Chute(fieldvar.id, fieldvar.toString()))
                    ctxBoard.addEdge(fieldInt, 0, merge, 1, new Chute(fieldvar.id, fieldvar.toString()))
                    boardNVariableToIntersection.update((ctxBoard, fieldvar), merge)
                  } else {
                    val con = Intersection.factory(Intersection.Kind.CONNECT)
                    ctxBoard.addNode(con)
                    ctxBoard.addEdge(subboard, 1, con, 0, new Chute(fieldvar.id, fieldvar.toString()))
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
                    ctxBoard.addEdge(recvInt, 0, subboard, 0, createChute(recvslot))

                    if (isUniqueSlot(rightslot)) {
                      val rightInt = findIntersection(ctxBoard, rightslot)
                      ctxBoard.addEdge(rightInt, 0, subboard, 1, createChute(rightslot))
                    } else {
                      val rightInt = findIntersection(ctxBoard, rightslot)
                      val split = Intersection.factory(Intersection.Kind.SPLIT)
                      ctxBoard.addNode(split)

                      ctxBoard.addEdge(rightInt, 0, split, 0, createChute(rightslot))
                      ctxBoard.addEdge(split, 1, subboard, 1, createChute(rightslot))

                      updateIntersection(ctxBoard, rightslot, split)
                    }

                    val con = Intersection.factory(Intersection.Kind.CONNECT)
                    ctxBoard.addNode(con)
                    ctxBoard.addEdge(subboard, 0, con, 0, createChute(recvslot))

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

            { // Connect the receiver to input and output 0
              val receiverInt = findIntersection(callerBoard, receiver)

              callerBoard.addEdge(receiverInt, 0, subboard, 0, createChute(receiver))

              val con = Intersection.factory(Intersection.Kind.CONNECT)
              callerBoard.addNode(con)
              callerBoard.addEdge(subboard, 0, con, 0, createChute(receiver))
              
              updateIntersection(callerBoard, receiver, con)
            }
            { // TODO: type arguments
            }
            { // Connect the arguments as inputs only 
              for (anarg <- args) {
                subboardPort += 1

                // TODO: merge this with RHS of assignment
                if (isUniqueSlot(anarg)) {
                  val anargInt = findIntersection(callerBoard, anarg)
                  callerBoard.addEdge(anargInt, 0, subboard, subboardPort, createChute(anarg))
                } else {
                  val anargInt = findIntersection(callerBoard, anarg)

                  val split = Intersection.factory(Intersection.Kind.SPLIT)
                  callerBoard.addNode(split)

                  callerBoard.addEdge(anargInt, 0, split, 0, createChute(anarg))
                  callerBoard.addEdge(split, 1, subboard, subboardPort, createChute(anarg))

                  updateIntersection(callerBoard, anarg, split)
                }
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
                  // println("Unhandled return type slot! " + result)
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
        /*if (cvar.varpos.isInstanceOf[ReturnVP]) {
          // Only the return variable is attached to outgoing.
          val outgoing = board.getOutgoingNode()
          board.addEdge(lastsect, 0, outgoing, 1, new Chute(cvar.id, cvar.toString()))
        } else {*/
          // Everything else simply gets terminated.
          val end = Intersection.factory(Intersection.Kind.END)
          board.addNode(end)
          board.addEdge(lastsect, 0, end, 0, new Chute(cvar.id, cvar.toString()))
        //}
      })

      boardToSelfIntersection foreach ( kv => { val (board, lastsect) = kv
        val outgoing = board.getOutgoingNode()
        val outthis = createThisChute()
        board.addEdge(lastsect, 0, outgoing, 0, outthis)
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
      // println("created board " + b + " with name " + name)
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
    def newSubboard(callerBoard: Board, calledvarpos: VariablePosition, calledname: String): Subnetwork = {
      val subboard = Intersection.subnetworkFactory(cleanUpForXML(calledname))
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
      board.addEdge(incoming, incoming.getOutputs().size(), start, 0, inthis)
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

    def findIntersection(board: Board, slot: Slot): Intersection = {
      slot match {
        case v: Variable => {
          boardNVariableToIntersection((board, v))
        }
        case LiteralThis =>
          boardToSelfIntersection(board)
        case LiteralNull => {
          val res = Intersection.factory(Intersection.Kind.START_BLACK_BALL)
          board.addNode(res)
          res
        }
        case lit: AbstractLiteral => {
          // TODO: Are all other literals non-null?
          val res = Intersection.factory(Intersection.Kind.START_WHITE_BALL)
          board.addNode(res)
          res
        }
        case NninfConstants.NULLABLE => {
          val res = Intersection.factory(Intersection.Kind.START_BLACK_BALL)
          board.addNode(res)
          res
        }
        case NninfConstants.NONNULL => {
          val res = Intersection.factory(Intersection.Kind.START_WHITE_BALL)
          board.addNode(res)
          res
        }
        case cv: CombVariable => {
          // TODO: Combvariables appear for BinaryTrees.
          val res = Intersection.factory(Intersection.Kind.START_WHITE_BALL)
          board.addNode(res)
          res
        }
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
        case LiteralNull => {
          // Nothing to do, we're always creating a new black ball
        }
        case lit: AbstractLiteral => {
          // Also nothing to do for other literals
        }
        case NninfConstants.NULLABLE => {
          // Nothing to do, we're always creating a new black ball
        }
        case NninfConstants.NONNULL => {
          // Nothing to do, we're always creating a new white ball
        }
        case cv: CombVariable => {
          // TODO: Combvariables appear for BinaryTrees.
        }
        case _ => {
          println("updateIntersection: unmatched slot: " + slot)
        }
      }
    }

    /** For "unique" slots we do not need to create splits, as a new, unique
     * intersection is generated each time.
     */
    def isUniqueSlot(slot: Slot): Boolean = {
      !(slot.isInstanceOf[Variable] || slot == LiteralThis) 
    }

    def createChute(slot: Slot): Chute = {
      slot match {
        case v: Variable =>
          new Chute(v.id, v.toString())
        case LiteralThis =>
          createThisChute()
        case LiteralNull => {
          val res = new Chute(-2, "null")
          res.setEditable(false)
          res.setNarrow(false)
          res
        }
        case lit: AbstractLiteral => {
          val res = new Chute(-3, lit.lit.toString())
          res.setEditable(false)
          res.setNarrow(true)
          res
        }
        case NninfConstants.NULLABLE => {
          val res = new Chute(-4, "nullable")
          res.setEditable(false)
          res.setNarrow(false)
          res
        }
        case NninfConstants.NONNULL => {
          val res = new Chute(-5, "nonnull")
          res.setEditable(false)
          res.setNarrow(true)
          res
        }
        case cv: CombVariable => {
          // TODO: Combvariables appear for BinaryTrees.
          val res = new Chute(-6, "combvar")
          res.setEditable(false)
          res.setNarrow(true)
          res
        }
        case _ => {
          println("createChute: unmatched slot: " + slot)
          null
        }
      }
    }

    def getFieldAccessorName(fvp: FieldVP): String = {
      fvp.getFQName + "--GET"
    }

    def getFieldSetterName(fvp: FieldVP): String = {
      fvp.getFQName + "--SET"
    }

    def createThisChute(): Chute = {
      val inthis = new Chute(-1, "this")
      inthis.setEditable(false)
      inthis.setNarrow(true)
      inthis
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