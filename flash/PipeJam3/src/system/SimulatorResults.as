package system 
{
	import graph.Edge;
	import graph.Port;
	public class SimulatorResults 
	{
		
		public var newPortTroublePoints:Vector.<Port>;
		public var removedPortTroublePoints:Vector.<Port>;
		public var newEdgeTroublePoints:Vector.<Edge>;
		public var removedEdgeTroublePoints:Vector.<Edge>;
		
		public function SimulatorResults(_newPortTroublePoints:Vector.<Port>, _removedPortTroublePoints:Vector.<Port>, 
                                         _newEdgeTroublePoints:Vector.<Edge>, _removedEdgeTroublePoints:Vector.<Edge>) 
		{
			newPortTroublePoints = _newPortTroublePoints;
			removedPortTroublePoints = _removedPortTroublePoints;
			newEdgeTroublePoints = _newEdgeTroublePoints;
			removedEdgeTroublePoints = _removedEdgeTroublePoints;
		}
	}
}