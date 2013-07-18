package scenes.game.components.dialogs
{
	import assets.AssetInterface;
	import assets.AssetsFont;
	
	import display.BasicButton;
	import display.NineSliceBatch;
	import display.NineSliceButton;
	import display.NineSliceToggleButton;
	import display.ScrollBarThumb;
	
	import feathers.controls.Label;
	import feathers.controls.List;
	import feathers.controls.ScrollBar;
	import feathers.controls.renderers.IListItemRenderer;
	import feathers.core.FeathersControl;
	
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import scenes.BaseComponent;
	
	import starling.display.Image;
	import starling.display.Quad;
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.events.EventDispatcher;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	import starling.textures.Texture;
	import starling.textures.TextureAtlas;
	
	import utils.XMath;
	
	public class SelectLevelList extends Sprite
	{
		protected var mainAtlas:TextureAtlas;
		protected var levelAtlas:TextureAtlas;
		
		protected var itemLabel:Label;
		protected var icon:Texture;
		
		private var background:NineSliceBatch;
		
		private var scrollbarBackground:Image;
		private var topArrow:Image;
		private var bottomArrow:Image;
		private var thumb:ScrollBarThumb;
	
		//remember passed in height, as # of child objects could expand content pane
		//and we want the clip rect to be this size
		private var setHeight:Number;
		
		protected var buttonPane:BaseComponent;
		protected var buttonPaneArray:Array;
		protected var levelArray:Array;
		protected var currentSelection:NineSliceToggleButton;
		
		public function SelectLevelList(_width:Number, _height:Number)
		{
			setHeight = _height;
			
			background = new NineSliceBatch(width, _height, _width /6.0, height / 6.0, "Game", "PipeJamSpriteSheetPNG", "PipeJamSpriteSheetXML", "BlueLightBox");
			addChild(background);
			
			var scrollbarWidth:Number = 10.0;
			
			mainAtlas = AssetInterface.getTextureAtlas("Game", "PipeJamSpriteSheetPNG", "PipeJamSpriteSheetXML");
			levelAtlas = AssetInterface.getTextureAtlas("Game", "PipeJamLevelSelectSpriteSheetPNG", "PipeJamLevelSelectSpriteSheetXML");
			
			topArrow = new Image(mainAtlas.getTexture(AssetInterface.PipeJamSubTexture_MenuArrowVertical));
			addChild(topArrow);
			topArrow.scaleX = .5;
			topArrow.scaleY = .5;
			topArrow.x = _width - topArrow.width - 1.5;
			topArrow.addEventListener(TouchEvent.TOUCH, onTouchUpArrow);
			
			bottomArrow = new Image(mainAtlas.getTexture(AssetInterface.PipeJamSubTexture_MenuArrowVertical));
			addChild(bottomArrow);
			bottomArrow.scaleX = .5;
			bottomArrow.scaleY = -.5;
			bottomArrow.x = _width - bottomArrow.width - 1.5;
			bottomArrow.y = _height;
			bottomArrow.addEventListener(TouchEvent.TOUCH, onTouchDownArrow);
			
			scrollbarBackground = new Image(mainAtlas.getTexture(AssetInterface.PipeJamSubTexture_ScrollBarTrack));
			addChild(scrollbarBackground);
			scrollbarBackground.x = _width - scrollbarWidth;
			scrollbarBackground.y = topArrow.height + 1;
			scrollbarBackground.height = _height - topArrow.height - bottomArrow.height - 2;
			scrollbarBackground.width = scrollbarWidth;
			
			thumb = new ScrollBarThumb(scrollbarBackground.y, scrollbarBackground.y+scrollbarBackground.height);
			thumb.addEventListener(starling.events.Event.TRIGGERED, onThumbTriggered);
			addChild(thumb);
			thumb.x = scrollbarBackground.x + scrollbarWidth/2 - thumb.width/2 - 1.5;
			thumb.y = scrollbarBackground.y;
			
			buttonPane = new BaseComponent();
			buttonPane.x = 0;
			buttonPane.y = 0;
			addChild(buttonPane);
			
			levelArray = new Array;
					
	//		addEventListener(starling.events.Event.ADDED_TO_STAGE, addedToStage);
	//		addEventListener(Event.TRIGGERED, onButtonToggle);
		}
		
		protected function onTouchUpArrow(event:TouchEvent):void
		{			
			if(thumb.enabled == false)
				return;
			
			var touches:Vector.<Touch> = event.touches;
			if (touches.length == 0) {
				return;
			}
			else if(event.getTouches(this, TouchPhase.BEGAN).length)
			{
				this.addEventListener(Event.ENTER_FRAME, updateUpScroll);
			}

			else if(event.getTouches(this, TouchPhase.ENDED).length)
			{
				this.removeEventListener(Event.ENTER_FRAME, updateUpScroll);
			}
		}
		
		protected function onTouchDownArrow(event:TouchEvent):void
		{			
			if(thumb.enabled == false)
				return;
			
			var touches:Vector.<Touch> = event.touches;
			if (touches.length == 0) {
				return;
			}
			else if(event.getTouches(this, TouchPhase.BEGAN).length)
			{
				this.addEventListener(Event.ENTER_FRAME, updateDownScroll);
			}
				
			else if(event.getTouches(this, TouchPhase.ENDED).length)
			{
				this.removeEventListener(Event.ENTER_FRAME, updateDownScroll);
			}
		}
		
		protected function updateUpScroll(e:Event):void
		{
			scrollPanel(-3);
		}
		
		protected function updateDownScroll(e:Event):void
		{
			scrollPanel(3);
		}
		
		public function setClipRect():void
		{
			if(buttonPane.clipRect == null)
			{
				var globalPoint:Point = this.localToGlobal(new Point(0,0));
				buttonPane.clipRect = new Rectangle(globalPoint.x,globalPoint.y,width-scrollbarBackground.width, setHeight);
			}
		}
		
		private function onThumbTriggered(e:Event):void
		{
			if(e.data != null)
			{
				var percentScrolled:Number = e.data as Number;
				
				if(buttonPane.height>setHeight)
					buttonPane.y = -(buttonPane.height-setHeight)*percentScrolled;
			}
		}
		
		private function scrollPanel(percentScrolled:Number):void
		{
			var currentPercent:Number = buttonPane.y/-(buttonPane.height-setHeight);
			trace(percentScrolled, currentPercent, buttonPane.height,setHeight);
			
			var totalNewScrollDistance:Number = currentPercent+percentScrolled/100;
			
			if(totalNewScrollDistance < -0.1)
				totalNewScrollDistance = -0.1;
			
			if(totalNewScrollDistance > 1.1)
				totalNewScrollDistance = 1.1;
			
			buttonPane.y = -(buttonPane.height-setHeight)*totalNewScrollDistance;
			thumb.setThumbPercent(totalNewScrollDistance*100);
		}
		
		private function onUpScrollTriggered(e:Event):void
		{
			// TODO Auto Generated method stub
			
		}
		
		private function onDownScrollTriggered(e:Event):void
		{
			// TODO Auto Generated method stub
			
		}
		
		public function setButtonArray(objArray:Array):void
		{
			levelArray = objArray;
			buttonPaneArray = new Array;
			
			var xpos:Number = width - scrollbarBackground.width;
			var widthSpacing:Number = xpos/2;
			var heightSpacing:Number = 60;
			for(var i:int = 0; i< objArray.length; i++)
			{
				var upicon:Image = new Image(levelAtlas.getTexture("DocumentIcon"));
				var downicon:Image = new Image(levelAtlas.getTexture("DocumentIconClick"));
				var overicon:Image = new Image(levelAtlas.getTexture("DocumentIconMouseover"));
//				var newButton:BasicButton = new BasicButton(iconup, iconover, icondown);
				var newButton:NineSliceToggleButton = ButtonFactory.getInstance().createDefaultToggleButton("",  widthSpacing - 2,  heightSpacing - 2);
				newButton.addEventListener(starling.events.TouchEvent.TOUCH, onLevelButtonTouched);
				addChild(newButton);
				buttonPaneArray.push(newButton);
				newButton.x = (widthSpacing)* (i%2);
				newButton.y = Math.floor(i/2)*(heightSpacing) + 2;
				
				newButton.setIcon(upicon, downicon, overicon);
				newButton.setText(objArray[i].name);
				if(objArray[i].unlocked == false)
					newButton.enabled = false;
				
				buttonPane.addChild(newButton);
				
				}
				//select first
				if(objArray.length > 0)
					setCurrentSelection(buttonPaneArray[0]);
		
			if(buttonPane.height<setHeight)
				thumb.enabled = false;
			else
				thumb.enabled = true;
		}
		
		private function onLevelButtonTouched(e:Event):void
		{
			// TODO Auto Generated method stub
			
		}
		
		protected var _index:int = -1;
		
		public function get index():int
		{
			return this._index;
		}
		
		public function set index(value:int):void
		{
			if(this._index == value)
			{
				return;
			}
			this._index = value;
	//		this.invalidate(INVALIDATION_FLAG_DATA);
		}
		
		protected var _data:Object;
		
		public function get data():Object
		{
			return this._data;
		}
		
		public function set data(value:Object):void
		{
			if(this._data == value)
			{
				return;
			}
			this._data = value;
//			this.invalidate(INVALIDATION_FLAG_DATA);
		}
		
		protected var _isSelected:Boolean;
		
		public function get isSelected():Boolean
		{
			return this._isSelected;
		}
		
		public function set isSelected(value:Boolean):void
		{
			if(this._isSelected == value)
			{
				return;
			}
			this._isSelected = value;
//			this.invalidate(INVALIDATION_FLAG_SELECTED);
			this.dispatchEventWith(Event.CHANGE);
		}
		

		protected function draw():void
		{

		}
		

		public function setCurrentSelection(button:NineSliceToggleButton):void
		{
			if(currentSelection)
				currentSelection.setToggleState(false);
			currentSelection = button;
			if(currentSelection)
				currentSelection.setToggleState(true);
			
		}
		
		public function getSelectedLevelObject():Object
		{
			var index:int = buttonPaneArray.indexOf(currentSelection);
			return levelArray[index];
		}
		
		public function getElementCount():int
		{
			return  levelArray.length;
		}
	}
}