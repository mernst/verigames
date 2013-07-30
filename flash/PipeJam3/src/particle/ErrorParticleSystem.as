package particle 
{
	import flash.utils.Dictionary;
	
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
		private static var errorTexture:Texture;
		private var mParticleSystem:PDParticleSystem;
		
		protected static var nextID:int = 0;
		public var id:int;
		//need to store these somewhere, as they get created before the world is finished
		public static var errorList:Dictionary = new Dictionary;
		
		public function ErrorParticleSystem() 
		{
			super();

			if (!errorInited) {
				errorInited = true;
				errorConfig = XML(new ErrorConfig());
				errorTexture = Texture.fromBitmap(new ErrorParticle());
			}
			
			id=nextID++;
            errorList[id] = this;
            mParticleSystem = new PDParticleSystem(errorConfig, errorTexture);
			
			addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
            addEventListener(Event.REMOVED_FROM_STAGE, onRemovedFromStage);
        }
        
        private function onAddedToStage(evt:Event):void
        {
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
			
			errorList[id] = null;
			dispatchEvent(new ErrorEvent(ErrorEvent.ERROR_REMOVED, this));
		}
	}

}