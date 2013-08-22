package dialogs
{
	import assets.AssetInterface;
	import assets.AssetsFont;
	
	import display.NineSliceBatch;
	import display.NineSliceButton;
	
	import events.MenuEvent;
	
	import feathers.controls.Label;
	
	import flash.display.DisplayObject;
	import flash.geom.Point;
	import flash.text.TextFormat;
	
	import networking.LoginHelper;
	
	import scenes.BaseComponent;
	import scenes.game.display.Level;
	
	import starling.display.BlendMode;
	import starling.display.Image;
	import starling.display.Quad;
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	import starling.extensions.pixelmask.PixelMaskDisplayObject;
	import starling.textures.Texture;
	
	public class SubmitLevelDialog extends BaseComponent
	{
		/** Button to save the current layout */
		public var submit_button:NineSliceButton;
		
		/** Button to close the dialog */
		public var cancel_button:NineSliceButton;
		
		private var background:NineSliceBatch;
		
		private var enjoymentQuad:Quad;
		private var difficultyQuad:Quad;
		
		private var enjoymentStarsBackground:Image;
		private var difficultyStarsBackground:Image;
		
		public var enjoymentRating:Number = 2.5;
		public var difficultyRating:Number = 2.5;
		
		protected var paddingWidth:int = 8;
		protected var paddingHeight:int = 8;
		protected var buttonHeight:int = 24;
		protected var buttonWidth:int = 40;
		
		public function SubmitLevelDialog(shapeWidth:Number, shapeHeight:Number)
		{
			super();
			
			background = new NineSliceBatch(shapeWidth, shapeHeight, shapeHeight / 3.0, shapeHeight / 3.0, "Game", "PipeJamSpriteSheetPNG", "PipeJamSpriteSheetXML", "MenuBoxFree");
			addChild(background);
			
			submit_button = ButtonFactory.getInstance().createButton("Submit", buttonWidth, buttonHeight, buttonHeight / 2.0, buttonHeight / 2.0);
			submit_button.addEventListener(starling.events.Event.TRIGGERED, onSubmitButtonTriggered);
			submit_button.x = background.width - paddingWidth - buttonWidth;
			submit_button.y = background.height - paddingHeight - buttonHeight;
			addChild(submit_button);	
			
			cancel_button = ButtonFactory.getInstance().createButton("Cancel", buttonWidth, buttonHeight, buttonHeight / 2.0, buttonHeight / 2.0);
			cancel_button.addEventListener(starling.events.Event.TRIGGERED, onCancelButtonTriggered);
			cancel_button.x = background.width - 2*paddingWidth - 2*buttonWidth;
			cancel_button.y = background.height - paddingHeight - buttonHeight;
			addChild(cancel_button);
			
			addEventListener(starling.events.Event.ADDED_TO_STAGE, onAddedToStage);	
		}
		
		protected function onAddedToStage(event:starling.events.Event):void
		{
			var title:Label = new Label();
			title.text = "Rate It!";
			addChild(title);
			title.textRendererProperties.textFormat = new TextFormat( AssetsFont.FONT_UBUNTU, 20, 0xffffff ); 
			title.x = (width-100)/2;
			
			var label1:Label = new Label();
			label1.text = "Did you enjoy that level?";
			label1.x = paddingWidth;
			label1.y = paddingHeight*2 + 20;
			addChild(label1);
			label1.textRendererProperties.textFormat = new TextFormat( AssetsFont.FONT_UBUNTU, 12, 0xffffff ); 
			
			var enjoymentStarsMaskBackgroundTexture:Texture = AssetInterface.getTexture("Game", "RatingStarsClass");
			var enjoymentStarsMask:Image = new Image(enjoymentStarsMaskBackgroundTexture);
			enjoymentStarsMask.width *= .6;
			enjoymentStarsMask.height *= .6;
			
			var enjoymentStars:PixelMaskDisplayObject = new PixelMaskDisplayObject();
			enjoymentStars.x = paddingWidth*2;
			enjoymentStars.y = paddingHeight*2.5 + label1.y + label1.height;
			enjoymentStars.width = enjoymentStarsMask.width;
			enjoymentStars.height = enjoymentStarsMask.height;
			enjoymentStars.addEventListener(TouchEvent.TOUCH, overEnjoymentStars);
			
			enjoymentQuad = new Quad(enjoymentStarsMask.width/2, enjoymentStarsMask.height, 0xff0000);
			enjoymentStars.mask = enjoymentStarsMask;
			
			var enjoymentBackgroundStarsTexture:Texture = AssetInterface.getTexture("Game", "RatingStarsClass");
			enjoymentStarsBackground = new Image(enjoymentBackgroundStarsTexture);
			enjoymentStarsBackground.x = enjoymentStars.x;
			enjoymentStarsBackground.y = enjoymentStars.y;
			enjoymentStarsBackground.width *= .6;
			enjoymentStarsBackground.height *= .6;
			enjoymentStarsBackground.addEventListener(TouchEvent.TOUCH, overEnjoymentStars);
			
			addChild(enjoymentStarsBackground);
			addChild(enjoymentStars);
			enjoymentStars.addChild(enjoymentQuad);

			var label2:Label = new Label();
			label2.text = "How hard was it?";
			label2.x = paddingWidth;
			label2.y = paddingHeight*2 + enjoymentStars.y + enjoymentStars.height;
			addChild(label2);
			label2.textRendererProperties.textFormat = new TextFormat( AssetsFont.FONT_UBUNTU, 12, 0xffffff ); 
			
			var difficultyStarsMaskBackgroundTexture:Texture = AssetInterface.getTexture("Menu", "RatingStarsClass");
			var difficultyStarsMask:Image = new Image(difficultyStarsMaskBackgroundTexture);
			difficultyStarsMask.width *= .6;
			difficultyStarsMask.height *= .6;
			
			var difficultyStars:PixelMaskDisplayObject = new PixelMaskDisplayObject();
			difficultyStars.x = paddingWidth*2;
			difficultyStars.y = paddingHeight*2.5 + label2.y + label2.height;
			difficultyStars.width = difficultyStarsMask.width;
			difficultyStars.height = difficultyStarsMask.height;
			difficultyStars.addEventListener(TouchEvent.TOUCH, overDifficultyStars);
			
			difficultyQuad = new Quad(difficultyStarsMask.width/2, difficultyStarsMask.height, 0xff0000);
			difficultyStars.mask = difficultyStarsMask;
			
			var difficultyBackgroundStarsTexture:Texture = AssetInterface.getTexture("Menu", "RatingStarsClass");
			difficultyStarsBackground = new Image(difficultyBackgroundStarsTexture);
			difficultyStarsBackground.x = difficultyStars.x;
			difficultyStarsBackground.y = difficultyStars.y;
			difficultyStarsBackground.width *= .6;
			difficultyStarsBackground.height *= .6;
			difficultyStarsBackground.addEventListener(TouchEvent.TOUCH, overDifficultyStars);
			addChild(difficultyStarsBackground);
			addChild(difficultyStars);
			difficultyStars.addChild(difficultyQuad);
		}
		
		private function overEnjoymentStars(e:TouchEvent):void
		{
			var returnVal:Number = overStarsDelta(e, enjoymentStarsBackground, enjoymentQuad);
			
			if(returnVal != -1)
				enjoymentRating = returnVal;
		}
		
		private function overDifficultyStars(e:TouchEvent):void
		{
			var returnVal:Number = overStarsDelta(e, difficultyStarsBackground, difficultyQuad);
			
			if(returnVal != -1)
				difficultyRating = returnVal;			 
		}
		
		private function overStarsDelta(e:TouchEvent, obj:Image, quad:Quad):Number
		{
			if(e.getTouches(this, TouchPhase.ENDED).length)
			{
				var touch:Touch = e.getTouches(this, TouchPhase.ENDED)[0];
				if(touch.tapCount > 0)
				{
					var touchPoint:Point = touch.getLocation(this);
					var globalPoint:Point = localToGlobal(touchPoint);
					var localPoint:Point = obj.globalToLocal(globalPoint);
					quad.width = localPoint.x*.6; //we shrink the image by this...
					return quad.width/obj.width;
				}
			}
			return -1;
		}
		
		
		private function onCancelButtonTriggered(e:starling.events.Event):void
		{
			visible = false;
		}
		
		private function onSubmitButtonTriggered(e:starling.events.Event):void
		{
			var loginHelper:LoginHelper = LoginHelper.getLoginHelper();
			
			visible = false;
			var eRating:Number = this.enjoymentRating*5.0;
			//round to two decimal places
			eRating *= 100;
			eRating = Math.round(eRating);
			eRating /= 100;
			loginHelper.levelObject.enjoymentRating = eRating;
			var dRating:Number = this.difficultyRating*5.0;
			//round to two decimal places
			dRating *= 100;
			dRating = Math.round(dRating);
			dRating /= 100;
			loginHelper.levelObject.difficultyRating = dRating;
			loginHelper.reportPlayerPreference((eRating*20).toString()); //0-100 scale
			loginHelper.reportPlayerPerformance((dRating*20).toString()); //0-100 scale
			dispatchEvent(new MenuEvent(MenuEvent.SUBMIT_LEVEL));
		}
	}
}