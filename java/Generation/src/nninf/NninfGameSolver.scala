package nninf

import checkers.inference._
import checkers.inference.pbssolver._

import checkers.util.AnnotationUtils
import scala.collection.mutable.HashMap
import com.sun.source.tree.Tree.Kind
import javax.lang.model.element.AnnotationMirror

import verigames.level._

class NninfGameSolver(variables: List[Variable],
  combvariables: List[CombVariable],
  constraints: List[Constraint],
  weights: List[WeightInfo],
  params: TTIRun)
  extends ConstraintSolver(variables, combvariables, constraints, weights, params) {

    // TODO: ensure that no CombVariables were created
    // assert combvariables.length == 0

    def solve(): Option[Map[AbstractVariable, AnnotationMirror]] = {

      // TODO: add an option for the file name
      val xmlFile = new java.io.File("World.xml") // params.optWorldXMLFileName)
      // TODO: check for existing file
      val output = new java.io.PrintStream(new java.io.FileOutputStream(xmlFile))
      new WorldXMLPrinter().print(createWorld(), output, null)
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

    def createWorld(): World = {
      val world = new World()
      createLevels(world)
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
     * For each slot (i.e. constraint variable) we keep a reference to the
     * Intersection that should be used as next input.
     * Output port 0 of the Intersection has to be free.
     */
    val variableToIntersection = new HashMap[AbstractVariable, Intersection]


    def createLevels(world: World) {
      createBoards(world)
      handleConstraints(world)
      finalizeWorld(world)
    }

    def createBoards(world: World) { 
      // First, go through all variables and create a level for each occurring
      // class and a board for each occurring method.
      variables foreach { cvar => {
        cvar.varpos match {
          case mvar: WithinMethodVP => {
            val fqcname = mvar.getFQClassName
            val level: Level = if (classToLevel.contains(fqcname)) {
                classToLevel(fqcname)
              } else {
                val l = new Level
                classToLevel += (fqcname -> l)
                l
              }

            val msig = mvar.getMethodSignature
            val board: Board = if (methToBoard.contains(msig)) {
                methToBoard(msig)
              } else {
                val b = newBoard(level, msig)
                methToBoard += (msig -> b)
                b
              }

            if (mvar.isInstanceOf[ParameterVP]) {
              // also for FieldVP, but that's not a InMethodVP...
              val incoming = board.getIncomingNode()
              val start = Intersection.factory(Intersection.Kind.CONNECT)
              board.addNode(start)
              board.addEdge(incoming, incoming.getOutputs().size(), start, 0, new Chute())
              variableToIntersection += (cvar -> start)
            } else if (mvar.isInstanceOf[ReturnVP] ||
                mvar.isInstanceOf[LocalInMethodVP] ||
                mvar.isInstanceOf[CastInMethodVP] ||
                mvar.isInstanceOf[InstanceOfInMethodVP]) {
              // should a local variable start as BLACK/WHITE or NO ball?
              val input = Intersection.factory(Intersection.Kind.START_NO_BALL)
              val start = Intersection.factory(Intersection.Kind.CONNECT)
              board.addNode(input)
              board.addNode(start)
              board.addEdge(input, 0, start, 0, new Chute)
              variableToIntersection += (cvar -> start)
            } else if (mvar.isInstanceOf[NewInMethodVP]) {
              val input = Intersection.factory(Intersection.Kind.START_WHITE_BALL)
              val start = Intersection.factory(Intersection.Kind.CONNECT)
              board.addNode(input)
              board.addNode(start)
              board.addEdge(input, 0, start, 0, new Chute)
              variableToIntersection += (cvar -> start)
            } else {
              println("TODO: unsupported method variable position: " + cvar + " pos: " + cvar.varpos.getClass())
            }
          }
          case clvar: WithinClassVP => {
            val fqcname = clvar.getFQClassName
            val level: Level = if (classToLevel.contains(fqcname)) {
                classToLevel(fqcname)
              } else {
                val l = new Level
                classToLevel += (fqcname -> l)
                l
              }

            val board: Board = if (classToBoard.contains(fqcname)) {
                classToBoard(fqcname)
              } else {
                val b = newBoard(level, fqcname)
                classToBoard += (fqcname -> b)
                b
              }

            if (clvar.isInstanceOf[FieldVP]) {
              // In the field type
              val incoming = board.getIncomingNode()
              val start = Intersection.factory(Intersection.Kind.CONNECT)
              board.addNode(start)
              board.addEdge(incoming, incoming.getOutputs().size(), start, 0, new Chute())
              variableToIntersection += (cvar -> start)
            } else if (clvar.isInstanceOf[NewInFieldInitVP] ||
                clvar.isInstanceOf[NewInStaticInitVP]) {
              val input = Intersection.factory(Intersection.Kind.START_WHITE_BALL)
              val start = Intersection.factory(Intersection.Kind.CONNECT)
              board.addNode(input)
              board.addNode(start)
              board.addEdge(input, 0, start, 0, new Chute)
              variableToIntersection += (cvar -> start)
            } else if (clvar.isInstanceOf[WithinFieldVP] ||
                clvar.isInstanceOf[WithinStaticInitVP]) {
              // Things like casts in a field initializer
              val input = Intersection.factory(Intersection.Kind.START_NO_BALL)
              val start = Intersection.factory(Intersection.Kind.CONNECT)
              board.addNode(input)
              board.addNode(start)
              board.addEdge(input, 0, start, 0, new Chute)
              variableToIntersection += (cvar -> start)
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

    def handleConstraints(world: World) {
      constraints foreach { constraint => {
        constraint match {
          case SubtypeConstraint(sub, sup) => {
            // No need to generate something for trivial super/sub-types.
            if (sup != NninfConstants.NULLABLE &&
                sub != NninfConstants.NONNULL) {
              println(sub + " <: " + sup)

              if (sub == LiteralNull) {
                // Assume sup is a variable. Alternatives?
                val supvar = sup.asInstanceOf[Variable]
                val board = variableToBoard(supvar)
                val blackball = Intersection.factory(Intersection.Kind.START_BLACK_BALL)
                val merge = Intersection.factory(Intersection.Kind.MERGE)
                val lastIntersection = variableToIntersection(supvar)

                board.addNode(blackball)
                board.addNode(merge)

                board.addEdge(lastIntersection, 0, merge, 0, new Chute)
                board.addEdge(blackball, 0, merge, 1, new Chute)

                variableToIntersection.update(supvar, merge)
              } else {
                // TODO: Let's assume both sub and sup are variables. Other cases?
                val subvar = sub.asInstanceOf[Variable]
                val supvar = sup.asInstanceOf[Variable]
                val board = findBoard(subvar, supvar)

                val merge = Intersection.factory(Intersection.Kind.MERGE)
                val split = Intersection.factory(Intersection.Kind.SPLIT)
                val sublast = variableToIntersection(subvar)
                val suplast = variableToIntersection(supvar)

                board.addNode(merge)
                board.addNode(split)

                // TODO: which variable get's the merge output??
                board.addEdge(sublast, 0, merge, 0, new Chute)
                board.addEdge(suplast, 0, split, 0, new Chute)
                board.addEdge(split, 1, merge, 1, new Chute)

                variableToIntersection.update(subvar, merge)
                variableToIntersection.update(supvar, split)
              }
            }
          }
          case EqualityConstraint(ell, elr) => {
            println(ell + " == " + elr)
          }
          case InequalityConstraint(ell, elr) => {
            println(ell + " != " + elr)
            // TODO: support var!=NULLABLE for now
            if (elr == NninfConstants.NULLABLE) {
              val ellvar = ell.asInstanceOf[Variable]
              val board = variableToBoard(ellvar);

              val con = Intersection.factory(Intersection.Kind.CONNECT)
              val elllast = variableToIntersection(ellvar)

              board.addNode(con)

              val chute = new Chute
              chute.setNarrow(true)

              board.addEdge(elllast, 0, con, 0, chute)

              variableToIntersection.update(ellvar, con)
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
        }
      }}
    }

    def finalizeWorld(world: World) {
      // Connect all intersections to the corresponding outgoing slot
      variableToIntersection foreach ( kv => { val (cvar, lastsect) = kv
        val board = lastsect.getBoard()

        if (cvar.varpos.isInstanceOf[ReturnVP]) {
          // Should only the return variable be attached to outgoing?
          // Also parameters?
          val outgoing = board.getOutgoingNode()
          val chute = new Chute()
          board.addEdge(lastsect, 0, outgoing, outgoing.getInputs().size(), chute)        
        } else {
          // everything else simply gets terminated
          val end = Intersection.factory(Intersection.Kind.END)
          board.addNode(end)
          val chute = new Chute()
          board.addEdge(lastsect, 0, end, 0, chute)
        }
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
      val cleanname = name.replace('(', '-')
              .replace(')', '-')
              .replace(':', '-')
              .replace('#', '-')
              .replace(';', '-')
              .replace('/', '-')
      level.addBoard(cleanname, b)
      
      b.addNode(Intersection.factory(Intersection.Kind.INCOMING))
      b.addNode(Intersection.factory(Intersection.Kind.OUTGOING))
      
      b
    }

    def variableToBoard(cvar: Variable): Board = {
      cvar.varpos match {
        case mvar: WithinMethodVP => {
          methToBoard(mvar.getMethodSignature)
        }
        case clvar: WithinClassVP => {
          classToBoard(clvar.getFQClassName)
        }
        case _ => {
          println("TODO: only supporting variables within a method" + cvar)
          null
        }
      }
    }

    def findBoard(cvar1: Variable, cvar2: Variable): Board = {
      val board1 = variableToBoard(cvar1)
      val board2 = variableToBoard(cvar2)

      if (board1==board2) {
        board1
      } else {
        val cvar1isField = cvar1.varpos.isInstanceOf[FieldVP]
        val cvar2isField = cvar2.varpos.isInstanceOf[FieldVP]
        if (!cvar1isField && !cvar2isField) {
          println("TODO: constraint between unrelated variables! " + cvar1 + " and " + cvar2)
          null
        } else if (cvar1isField && cvar2isField) {
          // both variables are fields, i.e. it's "f1 = f2".
          // Return the board for field 1.
          // Note that such an assignment is not placed into the
          // method where the assignment occurs.
          // TODO: discuss this.
          board1
        } else if (cvar1isField && !cvar2isField) {
          // TODO: use board2, create a node for the field.
          board2
        } else {
          // final case: !cvar1isField && cvar2isField
          board1
        }
      }
    }
}