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
	import utils.XMath;
	
	import scenes.BaseComponent;
	
	import starling.display.Image;
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.events.EventDispatcher;
	import starling.textures.Texture;
	import starling.textures.TextureAtlas;
	import starling.display.Quad;
	
	public class SelectLevelList extends Sprite
	{
		protected var atlas:TextureAtlas;
		
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
			
			atlas = AssetInterface.getTextureAtlas("Game", "PipeJamSpriteSheetPNG", "PipeJamSpriteSheetXML");
			
			topArrow = new Image(atlas.getTexture(AssetInterface.PipeJamSubTexture_MenuArrowVertical));
			addChild(topArrow);
			topArrow.scaleX = .5;
			topArrow.scaleY = .5;
			topArrow.x = _width - topArrow.width - 1.5;
			
			bottomArrow = new Image(atlas.getTexture(AssetInterface.PipeJamSubTexture_MenuArrowVertical));
			addChild(bottomArrow);
			bottomArrow.scaleX = .5;
			bottomArrow.scaleY = -.5;
			bottomArrow.x = _width - bottomArrow.width - 1.5;
			bottomArrow.y = _height;

			scrollbarBackground = new Image(atlas.getTexture(AssetInterface.PipeJamSubTexture_ScrollBarTrack));
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
				buttonPane.y = -(buttonPane.height-setHeight)*percentScrolled;
			}
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
			var widthSpacing:Number = xpos/3;
			for(var i:int = 0; i< objArray.length; i++)
			{
				var icon:Image = new Image(atlas.getTexture(AssetInterface.PipeJamSubTexture_GrayDarkPlug));
//				var icondown:Image = new Image(atlas.getTexture(AssetInterface.PipeJamSubTexture_GrayDarkPlug));
//				var iconover:Image = new Image(atlas.getTexture(AssetInterface.PipeJamSubTexture_GrayDarkPlug));
//				var newButton:BasicButton = new BasicButton(iconup, iconover, icondown);
				var newButton:NineSliceToggleButton = ButtonFactory.getInstance().createToggleButton("",  widthSpacing - 2,  widthSpacing - 2, 0, 0);
				newButton.addEventListener(starling.events.TouchEvent.TOUCH, onLevelButtonTouched);
				addChild(newButton);
				buttonPaneArray.push(newButton);
				newButton.x = (widthSpacing)* (i%3);
				newButton.y = Math.floor(i/3)*(widthSpacing);
				
				newButton.setIcon(icon);
				newButton.setText(objArray[i].name);
				if(objArray[i].unlocked == false)
					newButton.enabled = false;
				
				buttonPane.addChild(newButton);
				
				//select first, to 
				if(i == 0)
					setCurrentSelection(newButton);
			}
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