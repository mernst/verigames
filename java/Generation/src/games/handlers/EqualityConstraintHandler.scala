package games.handlers

import games.GameSolver
import verigames.level.{Board, Subboard, Chute, Intersection}
import checkers.inference._
import checkers.types.AnnotatedTypeMirror
import checkers.types.AnnotatedTypeMirror.{AnnotatedTypeVariable, AnnotatedDeclaredType}

/**
 * Handler for an equality constraint--for equality constraints, we just need to
 * link the two pipes corresponding to the slots so that they will always have
 * the same width.
 *
 * @param constraint
 * @param gameSolver
 */

case class EqualityConstraintHandler( override val constraint : EqualityConstraint,
                                      gameSolver : GameSolver )
  extends ConstraintHandler[EqualityConstraint] {

  //NOTE: If a variable isn't declared in this file then it likely comes from gameSolver
  val EqualityConstraint(leftVar : AbstractVariable, rightVar : AbstractVariable) = constraint

  override def handle( ) {
    import gameSolver._
    val leftBoard  = gameSolver.variablePosToBoard(leftVar.varpos)
    val rightBoard = gameSolver.variablePosToBoard(rightVar.varpos)

    val leftCon  = Intersection.factory(Intersection.Kind.CONNECT)
    val rightCon = Intersection.factory(Intersection.Kind.CONNECT)

    val lastLeft  = gameSolver.boardNVariableToIntersection((leftBoard, leftVar))
    val lastRight = gameSolver.boardNVariableToIntersection((rightBoard, rightVar))

    leftBoard.addNode(leftCon)
    rightBoard.addNode(rightCon)

    val leftPipe  = new Chute(leftVar.id, leftVar.toString())
    val rightPipe = new Chute(rightVar.id, rightVar.toString())

    val level = variablePosToLevel(leftVar.varpos)
    level.linkByVarID(leftVar.id, rightVar.id)

    leftBoard.addEdge(lastLeft, "output", leftCon, "input", leftPipe)
    rightBoard.addEdge(lastRight, "output", rightCon, "input", rightPipe)

    boardNVariableToIntersection.update((leftBoard, leftVar), leftCon)
    boardNVariableToIntersection.update((rightBoard, rightVar), rightCon)
  }
}
