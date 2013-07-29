package particle 
{
	import starling.core.Starling;
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.extensions.PDParticleSystem;
	import starling.textures.Texture;
	
	public class FanfareParticleSystem extends Sprite 
	{
		[Embed(source = "../../lib/assets/particle/fanfare.pex", mimeType = "application/octet-stream")]
		private static const FanfareConfig:Class;
		
		[Embed(source = "../../lib/assets/particle/fanfare_particle.png")]
		private static const FanfareParticle:Class;
		
		private static const FanfareXML:XML = XML(new FanfareConfig());
		private static const fanfareTexture:Texture = Texture.fromBitmap(new FanfareParticle());
		private var mParticleSystem:PDParticleSystem;
		
		public function FanfareParticleSystem()
		{
			super();
			mParticleSystem = new PDParticleSystem(FanfareXML, fanfareTexture);
        }
        
        public function start():void
        {
            mParticleSystem.emitterX = 0;
            mParticleSystem.emitterY = 0;
            mParticleSystem.start();
            addChild(mParticleSystem);
            Starling.juggler.add(mParticleSystem);
        }
		
		public function get particleX():Number
		{
			return mParticleSystem.emitterX;
		}
		
		public function get particleY():Number
		{
			return mParticleSystem.emitterY;
		}
		
		public function set particleX(value:Number):void
		{
			mParticleSystem.emitterX = value;
		}
		
		public function set particleY(value:Number):void
		{
			mParticleSystem.emitterY = value;
		}
		
		public function stop():void
		{
			mParticleSystem.stop();
		}
		
		override public function dispose():void
		{
			mParticleSystem.removeFromParent(true);
			Starling.juggler.remove(mParticleSystem);
			super.dispose();
		}
	}

}