package display 
{
	import assets.AssetInterface;
	import starling.display.BlendMode;
	import starling.display.Image;
	import starling.display.Quad;
	import starling.display.QuadBatch;
	import starling.display.Sprite;
	import starling.textures.Texture;
	
	public class RoundedRect extends Sprite 
	{
		private var mWidth:Number;
		private var mHeight:Number;
		private var mRadius:Number;
		private var mColor:Number;
		private var mRoundTopLeft:Boolean;
		private var mRoundTopRight:Boolean;
		private var mRoundBottomLeft:Boolean;
		private var mRoundBottomRight:Boolean;
		
		private var mTopQuad:Quad;
		private var mBottomQuad:Quad;
		private var mLeftQuad:Quad;
		private var mRightQuad:Quad;
		private var mCenterQuad:Quad;
		
		private var mTopLeftCorner:Image;
		private var mTopRightCorner:Image;
		private var mBottomLeftCorner:Image;
		private var mBottomRightCorner:Image;
		
		private var mBatch:QuadBatch = new QuadBatch();
		private var mCornerBatch:QuadBatch = new QuadBatch();
		
		public function RoundedRect(_width:Number, _height:Number, _radius:Number, _color:Number,
		                            _roundTopLeft:Boolean = true, _roundTopRight:Boolean = true,
									_roundBottomLeft:Boolean = true, _roundBottomRight:Boolean = true)
		{
			super();
			mWidth = _width;
			mHeight = _height;
			mRadius = _radius;
			// Force radius to be <= width/2, height/2
			if (mRadius > mWidth / 2)
				mRadius = mWidth / 2;
			if (mRadius > mHeight / 2)
				mRadius = mHeight / 2;
			mColor = _color;
			mRoundTopLeft = _roundTopLeft;
			mRoundTopRight = _roundTopRight;
			mRoundBottomLeft = _roundBottomLeft;
			mRoundBottomRight = _roundBottomRight;
			
			addChild(mCornerBatch);
			addChild(mBatch);
			
			const BUFFER:Number = mRadius * 0.18; // Overlap to prevent gaps between rounded corners and quads
			
			var topBotWidth:Number = mWidth - 2 * mRadius + 2 * BUFFER;
			var topBotX:Number = mRadius - BUFFER;
			
			var topWidth:Number = topBotWidth;
			var topX:Number = topBotX;
			if (!mRoundTopLeft) {
				topWidth += mRadius - BUFFER;
				topX = 0;
			}
			if (!mRoundTopRight) {
				topWidth += mRadius - BUFFER;
			}
			mTopQuad = new Quad(topWidth, mRadius, mColor);
			mTopQuad.x = topX;
			mTopQuad.y = 0;
			mTopQuad.blendMode = BlendMode.NONE;
			mBatch.addQuad(mTopQuad);
			
			var botWidth:Number = topBotWidth;
			var botX:Number = topBotX;
			if (!mRoundBottomLeft) {
				botWidth += mRadius - BUFFER;
				botX = 0;
			}
			if (!mRoundBottomRight) {
				botWidth += mRadius - BUFFER;
			}
			mBottomQuad = new Quad(botWidth, mRadius, mColor);
			mBottomQuad.x = botX;
			mBottomQuad.y = mHeight - mRadius;
			mBottomQuad.blendMode = BlendMode.NONE;
			mBatch.addQuad(mBottomQuad);
			
			var leftRightHeight:Number = mHeight - 2 * mRadius + 2 * BUFFER;
			var leftRightY:Number = mRadius - BUFFER;
			
			var leftHeight:Number = leftRightHeight;
			var leftY:Number = leftRightY;
			if (!mRoundTopLeft) {
				leftHeight += mRadius - BUFFER;
				leftY = 0;
			}
			if (!mRoundBottomLeft) {
				leftHeight += mRadius - BUFFER;
			}
			mLeftQuad = new Quad(mRadius, leftHeight, mColor);
			mLeftQuad.x = 0;
			mLeftQuad.y = leftY;
			mLeftQuad.blendMode = BlendMode.NONE;
			mBatch.addQuad(mLeftQuad);
			
			var rightHeight:Number = leftRightHeight;
			var rightY:Number = leftRightY;
			if (!mRoundTopRight) {
				rightHeight += mRadius - BUFFER;
				rightY = 0;
			}
			if (!mRoundBottomRight) {
				rightHeight += mRadius - BUFFER;
			}
			mRightQuad = new Quad(mRadius, rightHeight, mColor);
			mRightQuad.x = mWidth - mRadius;
			mRightQuad.y = rightY;
			mRightQuad.blendMode = BlendMode.NONE;
			mBatch.addQuad(mRightQuad);
			
			mCenterQuad = new Quad(mWidth - 2 * mRadius, mHeight - 2 * mRadius, mColor);
			mCenterQuad.x = mRadius;
			mCenterQuad.y = mRadius;
			mCenterQuad.blendMode = BlendMode.NONE;
			mBatch.addQuad(mCenterQuad);
			
			const colorToBeReplaced:uint = 0xFF000000;
			const newColor:uint = 0xFF000000 + mColor;
			const cornerTexture:Texture = AssetInterface.getTextureReplaceColor("Game", "CornerClass", colorToBeReplaced, newColor);
			const textureKey:String = "CornerClass" + "_" + colorToBeReplaced.toString(16) + "_" + newColor.toString(16);
			
			if (mRoundTopLeft) {
				mTopLeftCorner = CornerImage.getCornerImage(cornerTexture, textureKey);
				mTopLeftCorner.width = mTopLeftCorner.height = mRadius;
				mTopLeftCorner.rotation = -Math.PI / 2;
				mTopLeftCorner.x = 0;
				mTopLeftCorner.y = mRadius;
				mCornerBatch.addImage(mTopLeftCorner);
			}
			
			if (mRoundTopRight) {
				mTopRightCorner = CornerImage.getCornerImage(cornerTexture, textureKey);
				mTopRightCorner.width = mTopRightCorner.height = mRadius;
				mTopRightCorner.rotation = 0;
				mTopRightCorner.x = mWidth - mRadius;
				mTopRightCorner.y = 0;
				mCornerBatch.addImage(mTopRightCorner);
			}
			
			if (mRoundBottomLeft) {
				mBottomLeftCorner = CornerImage.getCornerImage(cornerTexture, textureKey);
				mBottomLeftCorner.width = mBottomLeftCorner.height = mRadius;
				mBottomLeftCorner.rotation = -Math.PI;
				mBottomLeftCorner.x = mRadius;
				mBottomLeftCorner.y = mHeight;
				mCornerBatch.addImage(mBottomLeftCorner);
			}
			
			if (mRoundBottomRight) {
				mBottomRightCorner = CornerImage.getCornerImage(cornerTexture, textureKey);
				mBottomRightCorner.width = mBottomRightCorner.height = mRadius;
				mBottomRightCorner.rotation = Math.PI / 2;
				mBottomRightCorner.x = mWidth;
				mBottomRightCorner.y = mHeight - mRadius;
				mCornerBatch.addImage(mBottomRightCorner);
			}
			
			flatten();
		}
	}

}


import flash.utils.Dictionary;
import starling.display.Image;
import starling.textures.Texture;

/* Use the same image per texture for the corners of the RoundRect to save use of vertex buffers, etc */
class CornerImage
{
	private static var mTextureToImage:Dictionary = new Dictionary();
	
	public static function getCornerImage(texture:Texture, textureName:String):Image
	{
		return new Image(texture);
		
		if (!mTextureToImage.hasOwnProperty(textureName)) {
			mTextureToImage[textureName] = new Image(texture);
		}
		return mTextureToImage[textureName] as Image;
		
	}
}