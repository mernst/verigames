package scenes.game.newdisplay
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.geom.Point;
	
	import assets.AssetInterface;
	
	import constraints.ConstraintValue;
	import constraints.ConstraintVar;
	
	import display.NineSliceBatch;
	
	import graph.PropDictionary;
	
	import scenes.game.display.GameEdgeContainer;
	import scenes.game.display.GameNode;
	import scenes.game.display.ScoreBlock;
	
	import starling.display.Image;
	import starling.display.Quad;
	import starling.events.Event;
	import starling.filters.BlurFilter;
	import starling.text.TextField;
	import starling.textures.TextureAtlas;

	public class GameNode2 extends scenes.game.display.GameNode
	{

		public var currentColor:int;
		
		protected var mAtlas:TextureAtlas;
		
		protected var skin:GameNode2Skin;
		
		public function GameNode2(_layoutObj:Object, _constraintVar:ConstraintVar, _draggable:Boolean = true)
		{
			super(_layoutObj, _constraintVar, _draggable);
			
			this.addEventListener(starling.events.Event.ADDED_TO_STAGE, onAddedToStage);
			//this.addEventListener(starling.events.Event.REMOVED_FROM_STAGE, removedFromStage);
		}
		
		private function onAddedToStage(evt:Event):void
		{
			x = boundingBox.x;
			y = boundingBox.y;
			
			var q:Quad = new Quad(200, 200);
			addChild(q);
		}
		
		public function setSkin(_skin:GameNode2Skin):void
		{
			skin = _skin;
		}
		override public function draw():void
		{
			
			
			if(!skin)
			{
				skin = new GameNode2Skin();
				addChild(skin);
			}
			
			currentColor = skin.draw(m_isWide, m_isEditable);

			
		//	skin.x = boundingBox.x + boundingBox.width/2 - skin.width/2;
		//	skin.y = boundingBox.y + boundingBox.height/2 - skin.height/2;
			
			for each(var oedge1:GameEdge in this.orderedOutgoingEdges)
			{
				oedge1.draw();
			}
			for each(var iedge1:GameEdge in this.orderedIncomingEdges)
			{
				iedge1.draw();
			}
//			var quad:Quad = new Quad(shapeHeight, shapeHeight);
//			quad.x = (boundingBox.width-shapeHeight)/2;
//			addChild(quad);
//			var textField:TextField = 
//				new TextField(100, 20, constraintVar.id, "Arial", 12, 0xffff00);
//			addChild(textField);
		}
		
		//adds edge to outgoing edge method (unless currently in vector), then sorts
		override public function setOutgoingEdge(edge:GameEdgeContainer):void
		{
			orderedOutgoingEdges.push(edge);
		}
		
		//adds edge to incoming edge method (unless currently in vector), then sorts
		override public function setIncomingEdge(edge:GameEdgeContainer):void
		{
			orderedIncomingEdges.push(edge);
		}
		
		//do nothing, since we don't care about ports
		override public function updatePortIndexes():void
		{
		}
		
		override public function componentMoved(delta:Point):void
		{

		}

	}
}