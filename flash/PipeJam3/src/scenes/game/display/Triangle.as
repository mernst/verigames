package scenes.game.display
{
	import starling.display.Quad;
	
	public class Triangle extends Quad
	{
		
		public function Triangle(width:Number, height:Number, color:uint=0xffffff, premultipliedAlpha:Boolean=true)
		{
			super(width, height, color, premultipliedAlpha);
			
			//move position 1 to make an isoceles triangle
			mVertexData.setPosition(1,width, height/2);
			//overlap 3 with 2, removing the fourth vertex leads to one vertex being black, for some reason
			mVertexData.setPosition(3, 0, height);
			mVertexData.setUniformColor(color);
			
			onVertexDataChanged();
		}
	}
}