package scenes.game.display
{
	import flash.geom.Point;

	public class TutorialManagerTextInfo
	{
		public var text:String;
		public var size:Point;
		public var pointToFn:Function;
		
		public function TutorialManagerTextInfo(_text:String, _size:Point, _pointToFn:Function)
		{
			text = _text;
			size = _size;
			pointToFn = _pointToFn;
		}
	}
}
