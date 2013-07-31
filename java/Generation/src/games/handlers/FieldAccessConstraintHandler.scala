package games.handlers

import checkers.inference._
import games.GameSolver
import verigames.level.Intersection.Kind._
import checkers.types.AnnotatedTypeMirror
import verigames.level.Subboard
import checkers.inference.util.TraversalUtil
import checkers.inference.Variable
import checkers.inference.FieldAccessConstraint
import misc.util.VGJavaConversions._
import games.util.SlotUtil._

/**
 * For every member field in our game world we actually create a "synthetic" getter/setter board ( i.e. boards
 * doesn't correspond to an actual method ).  When a field is accessed it looks like a method call to the synthetic
 * getter board.  Recall that all method boards when referenced from another board are represented by a Subboard
 * intersection.
 *
 * FieldAccessConstraintHandler takes a single FieldAccessConstraint and adds to the game board located by the
 * accessContext of the constraint a call to the "synthetic" getter board for the field identified by the
 * fieldType.  One of these should be created then disposed of foreach FieldAccessConstraint
 * <<TODO: ADD TO LINK EXPLAINING THIS>>
 *
 * Note:  The getter board should have a number of outputs equal to the number of variables that appear
 * in the type of the field. Also, the receiver will have a number of inputs/outputs equal to the number
 * of variables inside its declaration
 *
 * (E.g. The method board for:
 *
 *     private @VarAnnot(0) Map< @VarAnnot(1) String, @VarAnnot(2) List< @VarAnnot(3) Integer>>;
 *
 * would have an output for each of the VarAnnot's above and they would be attached in the order [0, 1, 2, 3].
 * TODO: Should this order instead mimic the order in which we actually create the variables?
 *
 *
 * @param constraint
 * @param gameSolver
 */

case class FieldAccessConstraintHandler( override val constraint : FieldAccessConstraint, override val gameSolver : GameSolver)
  extends ConstraintHandler[FieldAccessConstraint]{

  //NOTE: If a variable isn't declared in this file then it likely comes from gameSolver
  import gameSolver._

  val FieldAccessConstraint(accessContext, receiver, fieldAtm, fieldVp) = constraint

  /**
   * The board (corresponding to a method) in which the field was accessed
   */
  val accessBoard = variablePosToBoard(accessContext)

  /**
   * The create an Subboard intersection that corresponds with the getter board for this field
   */
  val getterSubboardIsect = addSubboardIntersection(accessBoard, fieldVp, getFieldAccessorName(fieldVp))

  override def handle(  ) {

    if( !constraint.isFieldStatic ) {
      connectRecevierVariablesThrough( )
    }

    connectFieldVariablesToOutput( )

  }

  /**
   * Connect the receiver to the first n inputs/outputs where n is the number of variables in the receiver
   * TODO JB: Does this do the correct thing for other.field?  Does not seem like it
   */
  private def connectRecevierVariablesThrough( ) {
    val receiverVars =  listDeclVariables( receiver.get )

    receiverVars.foreach( recVar => {
      val receiverIsect = findIntersection( accessBoard, recVar )

      accessBoard.addEdge( receiverIsect, "output", getterSubboardIsect, ReceiverInPort, createChute(recVar) )
      val con = accessBoard.add( getterSubboardIsect, ReceiverOutPort, CONNECT, "input", createChute(recVar) )._2
      updateIntersection(accessBoard, recVar, con)
    })

  }

  private def connectFieldVariablesToOutput(  ) {
    //TODO JB: Currently Wildcards will have the same bug that AnnotatedTypeMirror's do but we won't
    //TODO JB: Be able to ignore them
    val outputs = listDeclVariables( fieldAtm )

    outputs.foreach {
      case fieldVar : Variable => {
        //If the field was previously accessed,
        if (boardNVariableToIntersection.contains( (accessBoard, fieldVar) ) ) {

          val fieldInt = boardNVariableToIntersection( (accessBoard, fieldVar) )

          val merge = accessBoard.add(getterSubboardIsect, ReturnOutPort + genericsOffset( fieldVar ), MERGE, "left", toChute( fieldVar ) )._2
          accessBoard.addEdge(fieldInt, "output", merge, "right", toChute( fieldVar ) )
          boardNVariableToIntersection.update( (accessBoard, fieldVar ), merge )
        } else {

          val con = accessBoard.add(getterSubboardIsect,  ReturnOutPort + genericsOffset( fieldVar ), CONNECT, "input", toChute( fieldVar ) )._2
          boardNVariableToIntersection.update( ( accessBoard, fieldVar ), con )
        }

      }
      case slot : Slot =>
        println( "Unhandled field type slot! " + slot + " for field access with VP= " + fieldVp )
    }
  }
}
