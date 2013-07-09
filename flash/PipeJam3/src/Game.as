package 
{
    import assets.AssetInterface;
    
    import events.NavigationEvent;
    
    import flash.external.ExternalInterface;
    import flash.ui.Keyboard;
    import flash.utils.Dictionary;
    import flash.utils.getDefinitionByName;
    import flash.utils.getQualifiedClassName;
    
    import scenes.BaseComponent;
    import scenes.Scene;
    
    import starling.core.Starling;
    import starling.display.BlendMode;
    import starling.display.Button;
    import starling.display.Image;
    import starling.display.MovieClip;
    import starling.display.Sprite;
    import starling.events.Event;
    import starling.events.KeyboardEvent;
    import starling.text.TextField;
    import starling.textures.Texture;
    import starling.utils.VAlign;

    public class Game extends BaseComponent
    {
        protected var mMainMenu:Sprite;
        protected var mCurrentScene:Scene;
		protected var scenesToCreate:Dictionary = new Dictionary;
		protected var sceneDictionary:Dictionary = new Dictionary;
		
		protected var busyAnimationImages:Vector.<Texture> = null;
		protected var busyAnimationMovieClip:MovieClip;
		
		public static var START_BUSY_ANIMATION:String = "startBusyAnimation";
		public static var STOP_BUSY_ANIMATION:String = "stopBusyAnimation";

		
		public static var SUPPRESS_TRACE_STATEMENTS:Boolean = true;
		
        public function Game()
        {
            // The following settings are for mobile development (iOS, Android):
            //
            // You develop your game in a *fixed* coordinate system of 480x320; the game might 
            // then run on a device with a different resolution, and the assets class will
            // provide textures in the most suitable format.
            Starling.current.stage.stageWidth  = Constants.GameWidth;
            Starling.current.stage.stageHeight = Constants.GameHeight;
            assets.AssetInterface.contentScaleFactor = Starling.current.contentScaleFactor;
			
			addEventListener(NavigationEvent.CHANGE_SCREEN, onChangeScreen);
			addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
			addEventListener(Event.REMOVED_FROM_STAGE, onRemovedFromStage);
			
			addEventListener(START_BUSY_ANIMATION, onStartBusyAnimation);
			addEventListener(STOP_BUSY_ANIMATION, onStopBusyAnimation);
        }
		
		protected function prepareAssets():void
		{
			assets.AssetInterface.prepareSounds();
		   assets.AssetInterface.loadBitmapFont("Game","DesyrelTexture", "DesyrelXml");	
		   
		   //load images if we haven't
		   if(busyAnimationImages == null)
		   {
				busyAnimationImages = new Vector.<Texture>();
				for(var i:int = 1; i<9; i++)
			   		busyAnimationImages.push(AssetInterface.getTexture("Game", "Loading"+i+"Class"));
				busyAnimationMovieClip = new MovieClip(busyAnimationImages, 4);
				
			   
		   }
		}
        
		protected function onAddedToStage(event:Event):void
        {
			removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
		}
        
		protected function onRemovedFromStage(event:Event):void
        {
         
		}
        
		protected function onChangeScreen(event:NavigationEvent):void
		{
			if(mCurrentScene)
				closeCurrentScene();
			
			showScene(event.scene);
		}
        protected function closeCurrentScene():void
        {
            mCurrentScene.removeFromParent();
            mCurrentScene = null;
        }
        
        protected function showScene(name:String):void
        {
            if (mCurrentScene) return;
            
			mCurrentScene = sceneDictionary[name];
			if(mCurrentScene == null)
			{
            	var sceneClass:Class = scenesToCreate[name];
            	mCurrentScene = Scene.getScene(sceneClass, this);
				sceneDictionary[name] = mCurrentScene;
				mCurrentScene.setPosition(0,0,480,320);
			}
			
			addChildAt(mCurrentScene, 0);
        }
		
		public function onStartBusyAnimation(e:Event):void
		{
			busyAnimationMovieClip.x = (width-busyAnimationMovieClip.width)/2;
			busyAnimationMovieClip.y = (height-busyAnimationMovieClip.height)/2;
			addChild(busyAnimationMovieClip);
			Starling.juggler.add(this.busyAnimationMovieClip);
		}
		
		public function onStopBusyAnimation(e:Event):void
		{
			removeChild(busyAnimationMovieClip);
			Starling.juggler.remove(this.busyAnimationMovieClip);
		}
		
		/**
		 * This prints any debug messages to Javascript if embedded in a webpage with a script "printDebug(msg)"
		 * @param	_msg Text to print
		 */
		public static function printDebug(_msg:String):void {
			if (!SUPPRESS_TRACE_STATEMENTS) {
				trace(_msg);
				if (ExternalInterface.available) {
					var reply:String = ExternalInterface.call("printDebug", _msg);
				}
			}
		}
		
		/**
		 * This prints any debug messages to Javascript if embedded in a webpage with a script "printDebug(msg)" - Specifically warnings that may be wanted even if other debug messages are not
		 * @param	_msg Warning text to print
		 */
		public static function printWarning(_msg:String):void {
			if (!SUPPRESS_TRACE_STATEMENTS) {
				trace(_msg);
				if (ExternalInterface.available) {
					var reply:String = ExternalInterface.call("printDebug", _msg);
				}
			}
		}
		
    }
}