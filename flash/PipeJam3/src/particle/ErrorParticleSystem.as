package particle 
{
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
		
		private static const errorConfig:XML = XML(new ErrorConfig());
		private static const errorTexture:Texture = Texture.fromBitmap(new ErrorParticle());
		private var mParticleSystem:PDParticleSystem;
		
		public function ErrorParticleSystem() 
		{
			super();
            
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
        }
		
		private function onRemovedFromStage(evt:Event):void
		{
			mParticleSystem.stop();
			mParticleSystem.removeFromParent();
			Starling.juggler.remove(mParticleSystem);
		}
		
	}

}