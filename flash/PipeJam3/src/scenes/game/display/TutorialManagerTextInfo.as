package scenes.game.display
{
	import flash.geom.Point;

	public class TutorialManagerTextInfo
	{
		public var text:String;
		public var size:Point;
		public var pointToFn:Function;
		public var pointDir:String;
		
		public function TutorialManagerTextInfo(_text:String, _size:Point, _pointToFn:Function, _pointDir:String)
		{
			text = _text;
			size = _size;
			pointToFn = _pointToFn;
			pointDir = _pointDir;
		}
	}
}
