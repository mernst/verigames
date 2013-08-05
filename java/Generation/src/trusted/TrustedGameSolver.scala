package trusted

import checkers.inference._
import javacutils.AnnotationUtils
import scala.collection.mutable.HashMap
import com.sun.source.tree.Tree.Kind
import javax.lang.model.element.AnnotationMirror
import verigames.level._
import checkers.inference.LiteralNull
import checkers.inference.AbstractLiteral
import games.GameSolver

class TrustedGameSolver extends GameSolver {

    // TODO: ensure that no CombVariables were created
    // assert combvariables.length == 0

    override def version: String = super.version + "\nTrustedGameSolver version 0.1"

    var otherReturn : Slot = null
    
    /**
     * Go through all constraints and add the corresponding piping to the boards.
     */
    override def handleConstraint(world: World, constraint: Constraint): Boolean = {
        constraint match {
          case SubtypeConstraint(sub, sup) => {
            // No need to generate something for trivial super/sub-types.
            if (sup != TrustedConstants.UNTRUSTED &&
                sub != TrustedConstants.TRUSTED) {

              if (sub == TrustedConstants.UNTRUSTED) {
                // For "null <: sup" create a black ball falling into sup.
                // println("null <: " + sup)

                // Assume sup is a variable. Alternatives?
                val supvar = sup.asInstanceOf[Variable]
                val board = variablePosToBoard(supvar.varpos)
                val blackball = Intersection.factory(Intersection.Kind.START_LARGE_BALL)
                val merge = Intersection.factory(Intersection.Kind.MERGE)
                val lastIntersection = boardNVariableToIntersection((board, supvar))

                board.addNode(blackball)
                board.addNode(merge)

                board.addEdge(lastIntersection, "0", merge, "0", new Chute(supvar.id, supvar.toString()))
                board.addEdge(blackball, "0", merge, "1", new Chute(-1, "untrusted string"))

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
                    board.addEdge(sublast, "0", merge, "1", createChute(sub))
                    board.addEdge(suplast, "0", merge, "0", createChute(sup))

                    updateIntersection(board, sup, merge)
                  } else if (isUniqueSlot(sup)) {
                    board.addEdge(sublast, "0", merge, "1", createChute(sub))
                    board.addEdge(suplast, "0", merge, "0", createChute(sup))

                    updateIntersection(board, sub, merge)
                  } else {
                    val split = Intersection.factory(Intersection.Kind.SPLIT)
                    board.addNode(split)

                    board.addEdge(sublast, "0", split, "0", createChute(sub))
                    board.addEdge(suplast, "0", merge, "0", createChute(sup))
                    board.addEdge(split, "1", merge, "1", createChute(sub))

                    updateIntersection(board, sub, split)
                    updateIntersection(board, sup, merge)
                  }
                }
              }
            }
          }
          case EqualityConstraint(leftslot, rightslot) => {
            if (rightslot == TrustedConstants.UNTRUSTED ||
                rightslot == TrustedConstants.TRUSTED) {
              // Assume leftslot is a variable. Alternatives?
              val leftvar = leftslot.asInstanceOf[Variable]
              val board = variablePosToBoard(leftvar.varpos)
              val con = Intersection.factory(Intersection.Kind.CONNECT)
              val lastIntersection = boardNVariableToIntersection((board, leftvar))

              board.addNode(con)

              val pipe = new Chute(leftvar.id, leftvar.toString())

              if (rightslot == TrustedConstants.UNTRUSTED) {
                pipe.setNarrow(false)
              } else {
                pipe.setNarrow(true)
              }
              pipe.setEditable(false)

              board.addEdge(lastIntersection, "0", con, "0", pipe)

              boardNVariableToIntersection.update((board, leftvar), con)
            } else {
              println("TODO: EqualityConstraint not handled: " + constraint)
            }
          }
          case InequalityConstraint(ctx, ell, elr) => {
            // println(ell + " != " + elr)
            // TODO: support var!=NULLABLE for now
            if (elr == TrustedConstants.UNTRUSTED) {
              if (ell == LiteralThis) {
                // Nothing to do if the LHS is "this", always non-null.
              } else {
                // TODO: adapt this to Trusted checker
                val ellvar = ell.asInstanceOf[Variable]
                val board = variablePosToBoard(ctx);

                val con = Intersection.factory(Intersection.Kind.CONNECT)
                board.addNode(con)

                val chute = new Chute(ellvar.id, ellvar.toString())
                chute.setPinched(true)

                val elllast = findIntersection(board, ellvar)

                board.addEdge(elllast, "0", con, "0", chute)

                updateIntersection(board, ellvar, con)
              }
            } else {
              println("TODO: uncovered inequality case!")
            }
          }
          case _ => {
            return super.handleConstraint(world, constraint)
          }
        }
        return true
    }

    def findIntersection(board: Board, slot: Slot): Intersection = {
      slot match {
        case v: Variable => {
          boardNVariableToIntersection((board, v))
        }
        case LiteralThis => {
          boardNVariableToIntersection( ( board, boardToSelfVariable(board) ) )
        }
        case lit: AbstractLiteral => {
          val res = Intersection.factory(Intersection.Kind.START_SMALL_BALL)
          board.addNode(res)
          res
        }
        case TrustedConstants.UNTRUSTED => {
          val res = Intersection.factory(Intersection.Kind.START_LARGE_BALL)
          board.addNode(res)
          res
        }
        case TrustedConstants.TRUSTED => {
          val res = Intersection.factory(Intersection.Kind.START_SMALL_BALL)
          board.addNode(res)
          res
        }
        case cv: CombVariable => {
          // TODO: Combvariables appear for BinaryTrees.
          val res = Intersection.factory(Intersection.Kind.START_SMALL_BALL)
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
        case TrustedConstants.UNTRUSTED => {
          // Nothing to do, we're always creating a new black ball
        }
        case TrustedConstants.TRUSTED => {
          // Nothing to do, we're always creating a new white ball
        }
        case LiteralThis => { //TODO JB: I don't think this should happen anymore
          boardNVariableToIntersection.update( (board, boardToSelfVariable( board )), inters )
        }
        case cv: CombVariable => {
          // TODO: Combvariables appear for BinaryTrees.
        }
        case _ => {
          println("updateIntersection: unmatched slot: " + slot)
        }
      }
    }

    def createChute(slot: Slot): Chute = {
      slot match {
        case v: Variable => {
          new Chute(v.id, v.toString())
        }
        case LiteralThis => {
          createThisChute()
        }
        case lit: AbstractLiteral => {
          val res = new Chute(-3, lit.lit.toString())
          res.setEditable(false)
          res.setNarrow(true)
          res
        }
        case TrustedConstants.UNTRUSTED => {
          val res = new Chute(-4, "untrusted")
          res.setEditable(false)
          res.setNarrow(false)
          res
        }
        case TrustedConstants.TRUSTED => {
          val res = new Chute(-5, "trusted")
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

    def createThisChute(): Chute = {
      val inthis = new Chute(-1, "this")
      inthis.setEditable(false)
      // TODO: why is "this" always trusted?
      inthis.setNarrow(true)
      inthis
    }

    def createReceiverChute( variable : Variable ) = createChute( variable )


    override def optimizeWorld(world: World) {
      // TODO: Any optimizations specific to the nullness system?
      super.optimizeWorld(world)
    }
}
