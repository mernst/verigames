package particle 
{
	import flash.utils.Dictionary;
	import graph.PropDictionary;
	import starling.display.Quad;
	import starling.extensions.ColorArgb;
	
	import events.ErrorEvent;
	
	import starling.core.Starling;
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.extensions.PDParticleSystem;
	import starling.textures.Texture;
	
	public class ErrorParticleSystem extends Sprite 
	{
		[Embed(source = "../../lib/assets/particle/error.pex", mimeType = "application/octet-stream")]
		private static const ErrorConfig:Class;
		
		[Embed(source = "../../lib/assets/particle/error_particle.png")]
		private static const ErrorParticle:Class;
		
		private static var errorInited:Boolean = false;
		private static var errorConfig:XML;
		public static var errorTexture:Texture;
		private var mParticleSystem:PDParticleSystem;
		private var mHitQuad:Quad;
		
		protected static var nextID:int = 0;
		public var id:int;
		//need to store these somewhere, as they get created before the world is finished
		public static var errorList:Dictionary = new Dictionary();
		public static var movedErrorList:Dictionary = new Dictionary();
		
		public function ErrorParticleSystem(errorProps:PropDictionary = null) 
		{
			super();
			
			if (!errorInited) {
				errorInited = true;
				errorConfig = XML(new ErrorConfig());
				errorTexture = Texture.fromBitmap(new ErrorParticle());
			}
			
			id=nextID++;
            errorList[id] = this;
			movedErrorList[id] = this;
            mParticleSystem = new PDParticleSystem(errorConfig, errorTexture);
			if (errorProps && !errorProps.hasProp(PropDictionary.PROP_NARROW)) {
				for (var prop:String in errorProps.iterProps()) {
					if (prop.indexOf(PropDictionary.PROP_KEYFOR_PREFIX) == 0) {
						// If there's a MapGet error but no narrow error, change color
						// Original values:
						//<startColor  red="1.00" green="0.18" blue="0.08" alpha="1.00"/>
						//<finishColor red="0.90" green="0.16" blue="0.07" alpha="0.80"/>
						mParticleSystem.startColor = new ColorArgb(1.0, 0.0, 1.0, 1.0);
						mParticleSystem.endColor   = new ColorArgb(1.0, 0.2, 0.2, 0.8);
						break;
					}
				}
			}
			mHitQuad = new Quad(20, 10, 0xFFFFFF);
			mHitQuad.x = mHitQuad.y = -mHitQuad.width / 2.0;
			mHitQuad.alpha = 0;
			
			addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
            addEventListener(Event.REMOVED_FROM_STAGE, onRemovedFromStage);
        }
        
		public static function resetList():void
		{
			errorList = new Dictionary();
			movedErrorList = new Dictionary();
			nextID = 0;
		}
		
        private function onAddedToStage(evt:Event):void
        {
			addChild(mHitQuad);
			
            mParticleSystem.emitterX = 0;
            mParticleSystem.emitterY = 0;
            mParticleSystem.start();
            
            addChild(mParticleSystem);
            Starling.juggler.add(mParticleSystem);
			dispatchEvent(new ErrorEvent(ErrorEvent.ERROR_ADDED, this));
        }
		
		private function onRemovedFromStage(evt:Event):void
		{
			mParticleSystem.stop();
			mParticleSystem.removeFromParent();
			Starling.juggler.remove(mParticleSystem);
			delete errorList[id];
			delete movedErrorList[id];
			dispatchEvent(new ErrorEvent(ErrorEvent.ERROR_REMOVED, this));
		}
	}

}