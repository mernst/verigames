package scenes.game.display 
{
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	import starling.display.Quad;
	import starling.display.Sprite;
	
	public class NodeGroup extends GridChild 
	{
		public var nodeDict:Dictionary;
		private var nWideNodes:uint = 0;
		private var nNarrowNodes:uint = 0;
		private var nErrorNodes:uint = 0;
		
		public function NodeGroup(_layoutObject:Object, _id:String, _bb:Rectangle, _parentGrid:GridSquare, _nodeDict:Dictionary) 
		{
			super(_layoutObject, _id, _bb, _parentGrid);
			isEditable = true;
			calculateNodeInfo();
			nodeDict = _nodeDict;
		}
		
		public function calculateNodeInfo():void
		{
			var prevErrorNodes:uint = nErrorNodes;
			nWideNodes = nNarrowNodes = nErrorNodes = 0;
			for each (var node:Node in nodeDict) {
				if (node.isNarrow)
					nNarrowNodes++;
				else
					nWideNodes++;
				if (node.hasError()) nErrorNodes++;
			}
			var wasNarrow:Boolean = isNarrow;
			isNarrow = (nNarrowNodes > nWideNodes);
			if (isNarrow != wasNarrow || nErrorNodes != prevErrorNodes) setDirty();
		}
		
		public override function hasError():Boolean { return nErrorNodes > 0; }
		
		public override function createSkin():void
		{
			super.createSkin();
			skin = new Sprite();
			if (hasError()) {
				const LINE_WIDTH:uint = 5;
				var errQuad1:Quad = new Quad(bb.width, LINE_WIDTH, 0xAA0000);
				errQuad1.y = -LINE_WIDTH;
				var errQuad2:Quad = new Quad(bb.width, LINE_WIDTH, 0xAA0000);
				errQuad2.y = bb.height;
				var errQuad3:Quad = new Quad(LINE_WIDTH, bb.height, 0xAA0000);
				errQuad3.x = -LINE_WIDTH;
				var errQuad4:Quad = new Quad(LINE_WIDTH, bb.height, 0xAA0000);
				errQuad4.x = bb.width;
				skin.addChild(errQuad1);
				skin.addChild(errQuad2);
				skin.addChild(errQuad3);
				skin.addChild(errQuad4);
			}
			var mainQuad:Quad = new Quad(bb.width, bb.height, isNarrow ? 0x00FFFF : 0x002288);
			mainQuad.alpha = 0.3;
			skin.addChild(mainQuad);
			skin.x = bb.x - gridOffset.x - 0.5 * skin.width;
			skin.y = bb.y - gridOffset.y - 0.5 * skin.height;
			setDirty(true);
		}
		
		public override function removeSkin():void
		{
			if (skin) skin.removeFromParent(true);
			skin = null;
		}
		
		public override function select(selectedNodes:Dictionary):void
		{
			isSelected = true;
			for each (var node:Node in nodeDict) {
				node.select(selectedNodes);
			}
		}
		
		public override function unselect(selectedNodes:Dictionary):void
		{
			isSelected = false;
			for each (var node:Node in nodeDict) {
				node.unselect(selectedNodes);
			}
		}
		
	}

}