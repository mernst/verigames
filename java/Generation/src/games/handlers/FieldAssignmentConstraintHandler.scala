package games.handlers

import checkers.inference.{FieldVP, Variable, FieldAssignmentConstraint}
import games.GameSolver
import verigames.level.Intersection.Kind._
import checkers.inference.FieldAssignmentConstraint
import checkers.inference.Variable
import checkers.inference.FieldVP
import misc.util.VGJavaConversions._


case class FieldAssignmentConstraintHandler( override val constraint : FieldAssignmentConstraint,
                                             override val gameSolver : GameSolver)
  extends SubboardCallConstraintHandler[FieldVP, FieldAssignmentConstraint]( constraint, gameSolver ) {

  override val methodSignature =
    constraint.calledVp
      .map( gameSolver.getFieldSetterName _ )
      .getOrElse( gameSolver.getFieldSetterName( constraint.stubBoardUse.get.methodSignature ) )
}