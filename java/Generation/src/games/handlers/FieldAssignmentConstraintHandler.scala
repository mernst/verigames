package games.handlers

import checkers.inference.{FieldVP, Variable, FieldAssignmentConstraint}
import games.GameSolver
import verigames.level.Intersection.Kind._
import checkers.inference.FieldAssignmentConstraint
import checkers.inference.Variable
import checkers.inference.FieldVP
import misc.util.VGJavaConversions._

case class FieldAssignmentConstraintHandler( override val constraint : FieldAssignmentConstraint,
                                             override val gameSolver : GameSolver )
  extends ConstraintHandler[FieldAssignmentConstraint] {
  import gameSolver._

  val FieldAssignmentConstraint( context, receiver, field, rhs ) = constraint

  val ctxBoard = variablePosToBoard( context )

  override def handle() {
    //TODO JB:  This needs to be fixed, run on Picard histograms, and example would be Double d = 7.0/7.0;
    //TODO POSSIBILITY: Create constants for these types while the unboxing op is visited by the DFF?
    if(rhs == null) {
      return
    }
    
    field match {
      case fieldvar : Variable => {
        fieldvar.varpos match {
          case fvp: FieldVP => {
            val setterBoardISect = addSubboardIntersection(ctxBoard, fvp, getFieldSetterName(fvp))
            val recvInt = findIntersection(ctxBoard, receiver)
            ctxBoard.addEdge(recvInt, "output", setterBoardISect, ReceiverInPort, createChute(receiver))

            if (isUniqueSlot(rhs)) {
              val rightInt = findIntersection(ctxBoard, rhs)
              ctxBoard.addEdge(rightInt, "output", setterBoardISect, OutputPort + genericsOffset(fieldvar), createChute(rhs))

            } else {
              val rightInt =
                try {
                  findIntersection(ctxBoard, rhs)
                } catch{
                  case exc : NoSuchElementException =>
                    val ints = boardNVariableToIntersection.filterKeys(_._1 == ctxBoard)
                    return    //TODO JB: This is likely Generics related and should be removed in the future
                  case _ => null //TODO JB: Completely erroneous
                }
              val split = ctxBoard.add(rightInt, "output", SPLIT, "input", createChute(rhs))._2
              ctxBoard.addEdge(split, "split", setterBoardISect, OutputPort + genericsOffset(fieldvar), createChute(rhs))

              updateIntersection(ctxBoard, rhs, split)
            }

            val con = ctxBoard.add(setterBoardISect, ReceiverOutPort, CONNECT, "input", createChute(receiver))._2
            updateIntersection(ctxBoard, receiver, con)
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

}
