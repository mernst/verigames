package games.handlers

import checkers.inference.{Constant, Slot, WithinClassVP, StubBoardUseConstraint}
import games.GameSolver
import trusted.TrustedConstants
import scala.collection.mutable.ListBuffer
import verigames.level.StubBoard.StubConnection
import verigames.level.StubBoard

abstract class StubBoardUseConstraintHandler( override val constraint : StubBoardUseConstraint,
                                              val gameSolver : GameSolver)
  extends ConstraintHandler[StubBoardUseConstraint] {

  //TODO: Add a library method to be able to just query these rather than duplicating them here
  //TODO: and in EqualityConstraintHandler
  val narrowSlotTypes : List[Slot]
  val wideSlotTypes   : List[Slot]

  def isNarrow( nonVar : Slot ) = narrowSlotTypes.find( _ == nonVar ).isDefined

  val StubBoardUseConstraint( methodSignature, levelVp, receiver,
                              methodTypeParamBounds, classTypeParamBounds, args, result ) = constraint

  //NOTE: Any methods/variables that don't seem to exist in this class are imported from GameSolver
  import gameSolver._

  val level = classToLevel( levelVp.getFQClassName )

  override def handle() {
    val methodTypeParams = interlaceTypeArgsAndBounds( methodTypeParamBounds )
    val classTypeParams  = interlaceTypeArgsAndBounds( classTypeParamBounds  )

    val inputs =
      List( new StubConnection( ReceiverInPort + "0", isNarrow( receiver ) ) ) ++
      makeStubConnections( MethodTypeParamsInPort, methodTypeParams )    ++
      makeStubConnections( ClassTypeParamsInPort,  classTypeParams  )    ++
      makeStubConnections( ParamInPort, args )

    val outputs =
      List( new StubConnection( ReceiverOutPort + "0", isNarrow( receiver ) ) ) ++
      makeStubConnections( MethodTypeParamsOutPort, methodTypeParams )    ++
      makeStubConnections( ClassTypeParamsOutPort,  classTypeParams  )    ++
      makeStubConnections( ParamOutPort, args )                           ++
      makeStubConnections( ReturnOutPort, result )

    import scala.collection.JavaConversions._
    level.addStubBoard( cleanUpForXML(methodSignature), new StubBoard( inputs, outputs ) )
  }

  def interlaceTypeArgsAndBounds( typeArgs : List[(List[Constant], Constant)] ) : List[Constant] = {
    val slotBuffer = new ListBuffer[Constant]
    for( (typeArg, lowerBound) <- typeArgs ) {
      slotBuffer ++= typeArg
      slotBuffer +=  lowerBound
    }
    slotBuffer.toList
  }

  def makeStubConnections( portPrefix : String, constants : List[Constant] ) = {
    constants.zipWithIndex.map( {
      case ( constant, index ) => new StubConnection( portPrefix + index, isNarrow( constant ) )
    } )
  }

}