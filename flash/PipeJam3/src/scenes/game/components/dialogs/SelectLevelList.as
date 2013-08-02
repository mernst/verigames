package scenes.game.components.dialogs
{
	import assets.AssetInterface;
	import assets.AssetsFont;
	
	import display.BasicButton;
	import display.NineSliceBatch;
	import display.ScrollBarThumb;
	
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import scenes.BaseComponent;
	
	import starling.display.DisplayObject;
	import starling.display.Image;
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	import starling.textures.Texture;
	import starling.textures.TextureAtlas;
	
	public class SelectLevelList extends Sprite
	{
		protected var mainAtlas:TextureAtlas;
		protected var levelAtlas:TextureAtlas;
		
		protected var icon:Texture;
		
		private var background:NineSliceBatch;
		
		private var scrollbarBackground:Image;
		private var upArrow:Image;
		private var downArrow:Image;
		private var thumb:ScrollBarThumb;
	
		//remember passed in height, as # of child objects could expand content pane
		//and we want the clip rect to be this size
		private var setHeight:Number;
		
		//used by page up/down to multipy standard arrow key scroll distance
		protected var scrollMultiplier:Number = 1.0;
		
		protected var buttonPane:BaseComponent;
		protected var buttonPaneArray:Array;
		
		public function SelectLevelList(_width:Number, _height:Number)
		{
			setHeight = _height;
			
			background = new NineSliceBatch(width, _height, _width /6.0, height / 6.0, "Game", "PipeJamSpriteSheetPNG", "PipeJamSpriteSheetXML", "BlueLightBox");
			addChild(background);
			
			var scrollbarWidth:Number = 10.0;
			
			mainAtlas = AssetInterface.getTextureAtlas("Game", "PipeJamSpriteSheetPNG", "PipeJamSpriteSheetXML");
			levelAtlas = AssetInterface.getTextureAtlas("Game", "PipeJamLevelSelectSpriteSheetPNG", "PipeJamLevelSelectSpriteSheetXML");
			
			upArrow = new Image(mainAtlas.getTexture(AssetInterface.PipeJamSubTexture_MenuArrowVertical));
			addChild(upArrow);
			upArrow.scaleX = .5;
			upArrow.scaleY = .5;
			upArrow.x = _width - upArrow.width - 1.5;
			upArrow.addEventListener(TouchEvent.TOUCH, onTouchUpArrow);
			
			downArrow = new Image(mainAtlas.getTexture(AssetInterface.PipeJamSubTexture_MenuArrowVertical));
			addChild(downArrow);
			downArrow.scaleX = .5;
			downArrow.scaleY = -.5;
			downArrow.x = _width - downArrow.width - 1.5;
			downArrow.y = _height;
			downArrow.addEventListener(TouchEvent.TOUCH, onTouchDownArrow);
			
			scrollbarBackground = new Image(mainAtlas.getTexture(AssetInterface.PipeJamSubTexture_ScrollBarTrack));
			addChild(scrollbarBackground);
			scrollbarBackground.x = _width - scrollbarWidth;
			scrollbarBackground.y = upArrow.height + 1;
			scrollbarBackground.height = _height - upArrow.height - downArrow.height - 2;
			scrollbarBackground.width = scrollbarWidth;
			scrollbarBackground.addEventListener(TouchEvent.TOUCH, onTouchScrollbar);
			thumb = new ScrollBarThumb(scrollbarBackground.y, scrollbarBackground.y+scrollbarBackground.height);
			thumb.addEventListener(starling.events.Event.TRIGGERED, onThumbTriggered);
			addChild(thumb);
			thumb.x = scrollbarBackground.x + scrollbarWidth/2 - thumb.width/2 - 1.5;
			thumb.y = scrollbarBackground.y;
			
			buttonPane = new BaseComponent();
			buttonPane.x = 0;
			buttonPane.y = 0;
			addChild(buttonPane);
			
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
			var touch:Touch = event.getTouch(upArrow);
			if(touch == null)
				return;
			
			var currentPosition:Point = touch.getLocation(scrollbarBackground.parent);
			storedMouseY = currentPosition.y;
			if(event.getTouches(this, TouchPhase.BEGAN).length)
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
			var touch:Touch = event.getTouch(downArrow);
			if(touch == null)
				return;
			
			var currentPosition:Point = touch.getLocation(scrollbarBackground.parent);
			storedMouseY = currentPosition.y;
			if(event.getTouches(this, TouchPhase.BEGAN).length)
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
			if(storedMouseY > thumb.y + thumb.height/2)
				this.removeEventListener(Event.ENTER_FRAME, updateUpScroll);
			else
				scrollPanel(-3);
		}
		
		protected function updateDownScroll(e:Event):void
		{
			if(storedMouseY < thumb.y + thumb.height/2)
				this.removeEventListener(Event.ENTER_FRAME, updateDownScroll);
			else
				scrollPanel(3);
		}
		
		protected var directionUp:Boolean = true;
		protected var storedMouseY:Number = -1;
		protected function onTouchScrollbar(event:TouchEvent):void
		{			
			if(thumb.enabled == false)
				return;
			
			var touches:Vector.<Touch> = event.touches;
			if (touches.length == 0) {
				return;
			}

			var touch:Touch = event.getTouch(scrollbarBackground);
			if(touch == null)
				return;
			
			var currentPosition:Point = touch.getLocation(scrollbarBackground.parent);
			
			if(event.getTouches(this, TouchPhase.BEGAN).length)
			{
				storedMouseY = currentPosition.y;
				scrollMultiplier = 5.0;
				if(currentPosition.y < thumb.y)
				{
					directionUp = true;
					this.addEventListener(Event.ENTER_FRAME, updateUpScroll);
				}
				else 
				{
					directionUp = false;
					this.addEventListener(Event.ENTER_FRAME, updateDownScroll);
				}
			}
				
			else if(event.getTouches(this, TouchPhase.ENDED).length)
			{
				scrollMultiplier = 1.0;
				if(directionUp)
					this.removeEventListener(Event.ENTER_FRAME, updateUpScroll);
				else
					this.removeEventListener(Event.ENTER_FRAME, updateDownScroll);
			}
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
			
			percentScrolled = percentScrolled*scrollMultiplier;
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
		
		private function makeDocState(label:String, labelSz:uint, iconTexName:String, bgTexName:String):DisplayObject
		{
			const ICON_SZ:Number = 40;
			const DOC_WIDTH:Number = 128;
			const DOC_HEIGHT:Number = 50;
			const PAD:Number = 6;
			
			var icon:Image = new Image(levelAtlas.getTexture(iconTexName));
			icon.width = icon.height = ICON_SZ;
			icon.x = PAD;
			icon.y = DOC_HEIGHT / 2 - ICON_SZ / 2;
			
			var bg:NineSliceBatch = new NineSliceBatch(DOC_WIDTH * 4, DOC_HEIGHT * 4, 16, 16, "Game", "PipeJamLevelSelectSpriteSheetPNG", "PipeJamLevelSelectSpriteSheetXML", bgTexName);
			bg.scaleX = bg.scaleY = 0.25;
			
			var textField:TextFieldWrapper = TextFactory.getInstance().createTextField(label, AssetsFont.FONT_UBUNTU, DOC_WIDTH - ICON_SZ - 3 * PAD, DOC_HEIGHT - 2 * PAD, labelSz, 0xFFFFFF);
			textField.x = ICON_SZ + 2 * PAD;
			textField.y = PAD;
			
			var st:Sprite = new Sprite();
			st.addChild(bg);
			st.addChild(icon);
			st.addChild(textField);
			
			return st;
		}
		
		public function setButtonArray(objArray:Array, isTutorial:Boolean):void
		{
			buttonPaneArray = new Array;
			
			var xpos:Number = width - scrollbarBackground.width;
			var widthSpacing:Number = xpos/2;
			var heightSpacing:Number = 60;
			
			for(var ii:int = 0; ii < objArray.length; ++ ii) {
				var label:String = objArray[ii].name;
				var labelSz:uint = 12;
				var newButton:BasicButton;
				
				if (objArray[ii].unlocked) {
					var upstate:DisplayObject = makeDocState(label, labelSz, "DocumentIcon", "DocumentBackground");
					var downstate:DisplayObject = makeDocState(label, labelSz, "DocumentIconClick", "DocumentBackgroundClick");
					var overstate:DisplayObject = makeDocState(label, labelSz, "DocumentIconMouseover", "DocumentBackgroundMouseover");
					newButton = new BasicButton(upstate, overstate, downstate);
					if (isTutorial) {
						newButton.data = { level:objArray[ii].levelId };
					} else {
						newButton.data = { level:objArray[ii] };
					}
				} else {
					var lockstate:DisplayObject = makeDocState(label, labelSz, "DocumentIconLocked", "DocumentBackgroundLocked");
					newButton = new BasicButton(lockstate, lockstate, lockstate);
					newButton.enabled = false;
				}
				
				newButton.x = (widthSpacing) * (ii%2);
				newButton.y = Math.floor(ii/2) * (heightSpacing) + 2;
				
				buttonPane.addChild(newButton);
			}
			
			if(buttonPane.height<setHeight)
				thumb.enabled = false;
			else
				thumb.enabled = true;
		}
		
		private function onLevelButtonTouched(e:Event):void
		{
			// TODO Auto Generated method stub
		}
		
		protected function draw():void
		{
		}
	}
}
