package nninf

import checkers.inference._
import checkers.util.AnnotationUtils
import scala.collection.mutable.HashMap
import com.sun.source.tree.Tree.Kind
import javax.lang.model.element.AnnotationMirror
import verigames.level._
import checkers.inference.LiteralNull
import checkers.inference.AbstractLiteral
import games.GameSolver
import util.VGJavaConversions._
import Intersection.Kind._

class NninfGameSolver extends GameSolver {

    // TODO: ensure that no CombVariables were created
    // assert combvariables.length == 0

    override def version: String = super.version + "\nNninfGameSolver version 0.1"

    /**
     * Go through all constraints and add the corresponding piping to the boards.
     */
    override def handleConstraint(world: World, constraint: Constraint) {
        constraint match {
          case SubtypeConstraint(sub, sup) => {
            // TODO: CombVariables should be handled by flow sensitivity. Should revisit this when flow
            // sensitivity is integrated.
            if (sup.isInstanceOf[CombVariable])
              return;
            // No need to generate something for trivial super/sub-types.
            if (sup != NninfConstants.NULLABLE &&
                sub != NninfConstants.NONNULL) {
              var merge : Intersection = null
              var board : Board = null
              if (sub == LiteralNull) {
                // For "null <: sup" create a black ball falling into sup.
                // println("null <: " + sup)
                // Assume sup is a variable. Alternatives?
                val supvar = sup.asInstanceOf[Variable]
                board = variablePosToBoard(supvar.varpos)

                val lastIntersection = boardNVariableToIntersection((board, supvar))
                val merge = board.add(lastIntersection, "output", MERGE, "left", toChute(supvar))._2

                val blackballchute = new Chute(-1, "null literal")
                blackballchute.setEditable(false)

                val blackball  = board.add(Intersection.Kind.START_LARGE_BALL, "output", merge, "right", blackballchute)._1

                boardNVariableToIntersection.update((board, supvar), merge)
              } else {
                // Subtypes between arbitrary variables only happens for local variables.
                // TODO: what happens for "x = o.f"? Do I always create ASSIGNMENT constraints?
                // What about m(o.f)?
                board = findBoard(sub, sup)

                if (board!=null) {
                  // println(sub + " <: " + sup)

                  merge = Intersection.factory(Intersection.Kind.MERGE)
                  board.addNode(merge)
                  val sublast = findIntersection(board, sub)
                  val suplast = findIntersection(board, sup)

                  if (isUniqueSlot(sub)) {
                    board.addEdge(sublast, "output", merge, "left",  createChute(sub))
                    board.addEdge(suplast, "output", merge, "right", createChute(sup))

                    updateIntersection(board, sup, merge)
                  } else if (isUniqueSlot(sup)) {
                    board.addEdge(sublast, "output", merge, "left",  createChute(sub))
                    board.addEdge(suplast, "output", merge, "right", createChute(sup))

                    updateIntersection(board, sub, merge)
                  } else {
                    val split = Intersection.factory(Intersection.Kind.SPLIT)
                    board.addNode(split)

                    board.addEdge(sublast, "output", split, "input", createChute(sub))
                    board.addEdge(suplast, "output", merge, "left",  createChute(sup))
                    board.addEdge(split,   "split",  merge, "right", createChute(sub))

                    updateIntersection(board, sub, split)
                    updateIntersection(board, sup, merge)
                  }
                }
              }
            }
          }
          case EqualityConstraint(leftslot, rightslot) => {/*
            if (rightslot == NninfConstants.NONNULL ||
                rightslot == NninfConstants.NULLABLE) {
              // Assume leftslot is a variable. Alternatives?
              val leftvar = leftslot.asInstanceOf[Variable]
              val board = variablePosToBoard(leftvar.varpos)
              val con = Intersection.factory(Intersection.Kind.CONNECT)
              val lastIntersection = boardNVariableToIntersection((board, leftvar))

              board.addNode(con)

              val pipe = new Chute(leftvar.id, leftvar.toString())

              if (rightslot == NninfConstants.NULLABLE) {
                pipe.setNarrow(false)
              } else {
                pipe.setNarrow(true)
              }
              pipe.setEditable(false)

              board.addEdge(lastIntersection, 0, con, 0, pipe)

              boardNVariableToIntersection.update((board, leftvar), con)
            } else {
              println("TODO: EqualityConstraint not handled: " + constraint)
            }*/
          }
          case InequalityConstraint(ctx, ell, elr) => {
            // println(ell + " != " + elr)
            // TODO: support var!=NULLABLE for now
            if (elr == NninfConstants.NULLABLE) {
              if (ell == LiteralThis) {
                // Nothing to do if the LHS is "this", always non-null.
              } else if (ell.isInstanceOf[Constant]){
                // TODO
              } else {
                val ellvar = ell.asInstanceOf[Variable]
                val board = variablePosToBoard(ctx);
                val elllast = findIntersection(board, ellvar)

                val chute = toChute(ellvar)
                chute.setPinched(true)

                val con = board.add(elllast, "output", CONNECT, "input", chute)._2
                updateIntersection(board, ellvar, con)
              }
            } else {
              println("TODO: uncovered inequality case!")
            }
          }
          case _ => {
            super.handleConstraint(world, constraint)
          }
        }
    }

    def findIntersection(board: Board, slot: Slot): Intersection = {
      slot match {
        case v: Variable =>  boardNVariableToIntersection((board, v))
        case LiteralThis =>  boardToSelfIntersection(board)

        case LiteralNull             => board.addNode(START_LARGE_BALL)
        case NninfConstants.NULLABLE => board.addNode(START_LARGE_BALL)

        case lit: AbstractLiteral    => board.addNode(START_SMALL_BALL)  // TODO: Are all other literals non-null?
        case NninfConstants.NONNULL  => board.addNode(START_SMALL_BALL)
        case cv: CombVariable        => board.addNode(START_SMALL_BALL)  // TODO: Combvariables appear for BinaryTrees.

        case _ => {
          println("findIntersection: unmatched slot: " + slot)
          null
        }
      }
    }

    def updateIntersection(board: Board, slot: Slot, inters: Intersection) {
      slot match {
        case v: Variable =>  boardNVariableToIntersection.update((board, v), inters)
        case LiteralThis =>  boardToSelfIntersection.update(board, inters)

        case LiteralNull             => // Nothing to do, we're always creating a new black ball
        case lit: AbstractLiteral    => // Also nothing to do for other literals
        case NninfConstants.NULLABLE => // Nothing to do, we're always creating a new black ball
        case NninfConstants.NONNULL  => // Nothing to do, we're always creating a new white ball
        case cv: CombVariable        => // TODO: Combvariables appear for BinaryTrees.

        case _ =>  println("updateIntersection: unmatched slot: " + slot)

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

    def createThisChute(): Chute = {
      val inthis = new Chute(-1, "this")
      inthis.setEditable(false)
      inthis.setNarrow(true)
      inthis
    }


    override def optimizeWorld(world: World) {
      // TODO: Any optimizations specific to the nullness system?
      super.optimizeWorld(world)
    }
}