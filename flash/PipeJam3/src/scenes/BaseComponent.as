package scenes
{
	import flash.display3D.Context3D;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import assets.AssetInterface;
	
	import display.ToolTippableSprite;
	
	import scenes.game.components.GridViewPanel;
	
	import starling.core.RenderSupport;
	import starling.core.Starling;
	import starling.display.DisplayObject;
	import starling.display.DisplayObjectContainer;
	import starling.display.Image;
	import starling.display.MovieClip;
	import starling.display.Sprite;
	import starling.errors.MissingContextError;
	import starling.events.Event;
	import starling.events.TouchEvent;
	import starling.textures.Texture;
	import starling.textures.TextureAtlas;
	import display.RadioButton;

	public class BaseComponent extends ToolTippableSprite
	{	
		private var mClipRect:Rectangle;
				
		//initalized in Game
		static protected var loadingAnimationImages:Vector.<Texture> = null;
		static protected var waitAnimationImages:Vector.<Texture> = null;
		
		protected var busyAnimationMovieClip:MovieClip;
		
		//useful for debugging resource issues
		public static var nextIndex:int = 0;
		public var objectIndex:int;
		
		public function BaseComponent()
		{
			objectIndex = nextIndex++;
			super();
		}
		
		override public function dispose():void
		{
			disposeChildren();
			super.dispose();
		}
		
		public function disposeChildren():void
		{
			while (this.numChildren > 0) {
				var obj:DisplayObject = getChildAt(0);
				if (obj is BaseComponent) {
					(obj as BaseComponent).disposeChildren();
				}
				obj.removeFromParent(true);
			}
		}
		
		public override function render(support:RenderSupport, alpha:Number):void
		{
			if (mClipRect == null) super.render(support, alpha);
			else
			{
				var context:Context3D = Starling.context;
				if (context == null) throw new MissingContextError();
				 
				support.finishQuadBatch();
				support.scissorRectangle = mClipRect;
				
				super.render(support, alpha);
				
				support.finishQuadBatch();
				support.scissorRectangle = null;
			}
		}
		
		public override function hitTest(localPoint:Point, forTouch:Boolean=false):DisplayObject
		{
			// without a clip rect, the sprite should behave just like before
			if (mClipRect == null) return super.hitTest(localPoint, forTouch); 
			
			// on a touch test, invisible or untouchable objects cause the test to fail
			if (forTouch && (!visible || !touchable)) return null;
			
			if (mClipRect.containsPoint(localToGlobal(localPoint)))
				return super.hitTest(localPoint, forTouch);
			else
				return null;
		}
		
		public function get clipRect():Rectangle { return mClipRect; }
		public function set clipRect(value:Rectangle):void
		{
			if (value) 
			{
				if (mClipRect == null) mClipRect = value.clone();
				else mClipRect.setTo(value.x, value.y, value.width, value.height);
			}
			else mClipRect = null;
		}
		
		//use this to force the size of the object
		//it adds a 'transparent' image of the specified size (you can make it non-transparent by changing the alpha value.)
		public function setPosition(_x:Number, _y:Number, _width:Number, _height:Number, _alpha:Number = 0.0, _color:Number = 0x000000):void
		{
			this.x = _x;
			this.y = _y;
		}
		
		public function handleUndoEvent(undoEvent:starling.events.Event, isUndo:Boolean = true):void
		{
			
		}
		
		public function startBusyAnimation(animationParent:DisplayObjectContainer = null):MovieClip
		{
			busyAnimationMovieClip = new MovieClip(loadingAnimationImages, 4);
			
			if(!animationParent)
			{
				busyAnimationMovieClip.x = (Constants.GameWidth-busyAnimationMovieClip.width)/2;
				busyAnimationMovieClip.y = (Constants.GameHeight-busyAnimationMovieClip.height)/2;
				addChild(busyAnimationMovieClip);
			}
			else
			{
				busyAnimationMovieClip.x = (animationParent.width-busyAnimationMovieClip.width)/2;
				busyAnimationMovieClip.y = (animationParent.height-busyAnimationMovieClip.height)/2;
				animationParent.addChild(busyAnimationMovieClip);
			}
			Starling.juggler.add(this.busyAnimationMovieClip);
			
			return busyAnimationMovieClip;
		}
		
		public function stopBusyAnimation():void
		{
			if(busyAnimationMovieClip)
			{
				removeChild(busyAnimationMovieClip);
				Starling.juggler.remove(this.busyAnimationMovieClip);
				
				busyAnimationMovieClip.dispose();
				busyAnimationMovieClip = null;
			}
			
			
		}
		
		protected function createPaintBrushButton(style:String, onClickFunction:Function, offset:Boolean = false, toolTipText:String = ""):Sprite
		{
			var atlas:TextureAtlas = AssetInterface.getTextureAtlas("Game", "ParadoxSpriteSheetPNG", "ParadoxSpriteSheetXML");
			
			var buttonTexture:Texture = atlas.getTexture("Button"+style);
			var buttonOverTexture:Texture = atlas.getTexture("Button"+style+"Over");
			var buttonClickTexture:Texture = atlas.getTexture("Button"+style+"Click");
			
			var buttonImage:Image = new Image(buttonTexture);
			var buttonOverImage:Image = new Image(buttonOverTexture);
			var buttonClickImage:Image = new Image(buttonClickTexture);
			
			var paintBrushButton:RadioButton = new RadioButton(buttonImage, buttonOverImage, buttonClickImage, toolTipText);
			//			m_solver1Brush.addEventListener(TouchEvent.TOUCH, changeCurrentBrush);

			paintBrushButton.useHandCursor = true;
			paintBrushButton.addEventListener(Event.TRIGGERED, onClickFunction);
			paintBrushButton.width = paintBrushButton.height = 2 * GridViewPanel.PAINT_RADIUS;
			paintBrushButton.alpha = 0.7;
			paintBrushButton.name = style;
			
			if(offset)
			{
				paintBrushButton.x = -0.5 * paintBrushButton.width;
				paintBrushButton.y = -0.5 * paintBrushButton.height;
			
				//why do I do this? I think so I can keep the cursor parts together, but that might not be the reason any more
				var paintBrush:Sprite = new Sprite;
				paintBrush.addChild(paintBrushButton);
				return paintBrush;
			}

			return paintBrushButton;
		}
		
		protected function createPaintBrush(style:String, offset:Boolean = false):Sprite
		{
			var atlas:TextureAtlas = AssetInterface.getTextureAtlas("Game", "ParadoxSpriteSheetPNG", "ParadoxSpriteSheetXML");
			var brushTexture:Texture = atlas.getTexture(style);			
			var brushImage:Image = new Image(brushTexture);
			
			brushImage.width = brushImage.height = 2 * GridViewPanel.PAINT_RADIUS;
			if(offset)
			{
				brushImage.x = -0.5 * brushImage.width;
				brushImage.y = -0.5 * brushImage.height;
			}
			brushImage.alpha = 0.7;
			
			var paintBrush:Sprite = new Sprite;
			paintBrush.addChild(brushImage);
			
			paintBrush.name = style;
			
			return paintBrush;
		}
	}
}