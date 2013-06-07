package display 
{
	import assets.AssetInterface;
	import starling.display.BlendMode;
	import starling.display.Image;
	import starling.display.Quad;
	//import starling.display.QuadBatch;
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
			
			const BUFFER:Number = mRadius * 0.2; // Overlap to prevent gaps between rounded corners and quads
			if (mRadius < mWidth / 2) {
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
				addChild(mTopQuad);
				
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
				addChild(mBottomQuad);
			}
			
			if (mRadius < mHeight / 2) {
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
				addChild(mLeftQuad);
				
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
				addChild(mRightQuad);
			}
			
			if ((mRadius < mWidth / 2) || (mRadius < mHeight / 2)) {
				mCenterQuad = new Quad(mWidth - 2 * mRadius, mHeight - 2 * mRadius, mColor);
				mCenterQuad.x = mRadius;
				mCenterQuad.y = mRadius;
				mCenterQuad.blendMode = BlendMode.NONE;
				addChild(mCenterQuad);
			}
			
			var cornerTexture:Texture = AssetInterface.getTextureReplaceColor("Game", "CornerClass", 0xFF000000, (0xFF000000 + mColor));
			
			if (mRoundTopLeft) {
				mTopLeftCorner = new Image(cornerTexture);
				mTopLeftCorner.width = mTopLeftCorner.height = mRadius;
				mTopLeftCorner.rotation = -Math.PI / 2;
				mTopLeftCorner.x = 0;
				mTopLeftCorner.y = mRadius;
				addChild(mTopLeftCorner);
			}
			
			if (mRoundTopRight) {
				mTopRightCorner = new Image(cornerTexture);
				mTopRightCorner.width = mTopRightCorner.height = mRadius;
				mTopRightCorner.rotation = 0;
				mTopRightCorner.x = mWidth - mRadius;
				mTopRightCorner.y = 0;
				addChild(mTopRightCorner);
			}
			
			if (mRoundBottomLeft) {
				mBottomLeftCorner = new Image(cornerTexture);
				mBottomLeftCorner.width = mBottomLeftCorner.height = mRadius;
				mBottomLeftCorner.rotation = -Math.PI;
				mBottomLeftCorner.x = mRadius;
				mBottomLeftCorner.y = mHeight;
				addChild(mBottomLeftCorner);
			}
			
			if (mRoundBottomRight) {
				mBottomRightCorner = new Image(cornerTexture);
				mBottomRightCorner.width = mBottomRightCorner.height = mRadius;
				mBottomRightCorner.rotation = Math.PI / 2;
				mBottomRightCorner.x = mWidth;
				mBottomRightCorner.y = mHeight - mRadius;
				addChild(mBottomRightCorner);
			}
			
			this.flatten();
		}
	}

}