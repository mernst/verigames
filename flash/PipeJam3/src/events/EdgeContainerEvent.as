package events 
{
	import scenes.game.display.GameEdgeContainer;
	import scenes.game.display.GameEdgeJoint;
	import scenes.game.display.GameEdgeSegment;
	
	import starling.events.Event;
	
	public class EdgeContainerEvent extends Event 
	{
		public static const CREATE_JOINT:String = "CREATE_JOINT";
		public static const RUBBER_BAND_SEGMENT:String = "RUBBER_BAND_SEGMENT";
		public static const SEGMENT_MOVED:String = "SEGMENT_MOVED";
		public static const SAVE_CURRENT_LOCATION:String = "SAVE_CURRENT_LOCATION";
		public static const RESTORE_CURRENT_LOCATION:String = "RESTORE_CURRENT_LOCATION";
		public static const INNER_SEGMENT_CLICKED:String = "INNER_SEGMENT_CLICKED";
		public static const HOVER_EVENT_OVER:String = "HOVER_EVENT_OVER";
		public static const HOVER_EVENT_OUT:String = "HOVER_EVENT_OUT";
		
		public var segment:GameEdgeSegment;
		public var joint:GameEdgeJoint;
		public var container:GameEdgeContainer;
		public var segmentIndex:int;
		public var jointIndex:int;
		
		public function EdgeContainerEvent(type:String, _segment:GameEdgeSegment = null, _joint:GameEdgeJoint = null) 
		{
			super(type, true);
			segment = _segment;
			joint = _joint;
			if (segment && (segment.parent is GameEdgeContainer)) {
				container = segment.parent as GameEdgeContainer;
			} else if (joint && (joint.parent is GameEdgeContainer)) {
				container = joint.parent as GameEdgeContainer;
			}
			if (container != null) {
				if (segment != null) segmentIndex = container.getSegmentIndex(segment);
				if (joint != null) jointIndex = container.getJointIndex(joint);
			} else {
				trace("WARNING: Event expects edge segment or joint with a parent edge container.");
			}
		}
		
	}

}