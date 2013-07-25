package display 
{
	import assets.AssetInterface;
	
	import flash.geom.Rectangle;
	
	import starling.display.BlendMode;
	import starling.display.Image;
	import starling.display.Quad;
	import starling.display.QuadBatch;
	import starling.display.Sprite;
	import starling.textures.Texture;
	import starling.textures.TextureAtlas;
	import starling.utils.RectangleUtil;
	
	public class NineSliceBatch extends QuadBatch 
	{
		public static const TOP_LEFT:String = "TopLeft";
		public static const TOP:String = "Top";
		public static const TOP_RIGHT:String = "TopRight";
		public static const LEFT:String = "Left";
		public static const CENTER:String = "Center";
		public static const RIGHT:String = "Right";
		public static const BOTTOM_LEFT:String = "BottomLeft";
		public static const BOTTOM:String = "Bottom";
		public static const BOTTOM_RIGHT:String = "BottomRight";
		
		protected var mWidth:Number;
		protected var mHeight:Number;
		protected var mCx:Number;
		protected var mCy:Number;
		
		protected var mAtlas:TextureAtlas;
		
		protected var mTopLeft:Image;
		protected var mTop:Image;
		protected var mTopRight:Image;
		protected var mLeft:Image;
		protected var mCenter:Image;
		protected var mRight:Image;
		protected var mBottomLeft:Image;
		protected var mBottom:Image;
		protected var mBottomRight:Image;
		
		public function NineSliceBatch(_width:Number, _height:Number, _cX:Number, _cY:Number, 
		                               _atlasFile:String, _atlasImgName:String, _atlasXMLName:String, 
									   _atlasXMLTexturePrefix:String)
		{
			super();
			mWidth = _width;
			mHeight = _height;
			mCx = Math.min(_cX, mWidth / 2.0); // can't be > half the width
			mCy = Math.min(_cY, mHeight / 2.0); // can't be > half the height
			
			mAtlas = AssetInterface.getTextureAtlas(_atlasFile, _atlasImgName, _atlasXMLName);
			
			mTopLeft = new Image(mAtlas.getTexture(_atlasXMLTexturePrefix + TOP_LEFT));
			mTop = new Image(mAtlas.getTexture(_atlasXMLTexturePrefix + TOP));
			mTopRight = new Image(mAtlas.getTexture(_atlasXMLTexturePrefix + TOP_RIGHT));
			mLeft = new Image(mAtlas.getTexture(_atlasXMLTexturePrefix + LEFT));
			mCenter = new Image(mAtlas.getTexture(_atlasXMLTexturePrefix + CENTER));
			mRight = new Image(mAtlas.getTexture(_atlasXMLTexturePrefix + RIGHT));
			mBottomLeft = new Image(mAtlas.getTexture(_atlasXMLTexturePrefix + BOTTOM_LEFT));
			mBottom = new Image(mAtlas.getTexture(_atlasXMLTexturePrefix + BOTTOM));
			mBottomRight = new Image(mAtlas.getTexture(_atlasXMLTexturePrefix + BOTTOM_RIGHT));
			
			updateX();
			updateY();
			updateWidth();
			updateHeight();
			
			addImage(mTopLeft);
			addImage(mTop);
			addImage(mTopRight);
			addImage(mLeft);
			addImage(mCenter);
			addImage(mRight);
			addImage(mBottomLeft);
			addImage(mBottom);
			addImage(mBottomRight);
		}
		
		public static function createNineSlice(_width:Number, _height:Number, _cX:Number, _cY:Number, 
											   _atlasFile:String, _atlasImgName:String, _atlasXMLName:String, 
											   _atlasXMLTexturePrefix:String):NineSliceBatch
		{
			var atlas:TextureAtlas = AssetInterface.getTextureAtlas(_atlasFile, _atlasImgName, _atlasXMLName);
			var region:Rectangle = atlas.getRegion(_atlasXMLTexturePrefix);
			var usePrefix:String = _atlasXMLTexturePrefix + "__" + String(_cX) + "__" + String(_cY);
			
			if (!atlas.getRegion(usePrefix)) {
				var x0:Number = region.x;
				var x1:Number = region.x + _cX;
				var x2:Number = region.x + region.width - _cX;
				var y0:Number = region.y;
				var y1:Number = region.y + _cY;
				var y2:Number = region.y + region.height - _cY;
				var iw:Number = region.width - 2 * _cX;
				var ih:Number = region.height - 2 * _cY;
					
				atlas.addRegion(usePrefix + TOP_LEFT, new Rectangle(x0, y0, _cX, _cY));
				atlas.addRegion(usePrefix + TOP_RIGHT, new Rectangle(x2, y0, _cX, _cY));
				atlas.addRegion(usePrefix + BOTTOM_LEFT, new Rectangle(x0, y2, _cX, _cY));
				atlas.addRegion(usePrefix + BOTTOM_RIGHT, new Rectangle(x2, y2, _cX, _cY));

				atlas.addRegion(usePrefix + TOP, new Rectangle(x1, y0, iw, _cY));
				atlas.addRegion(usePrefix + BOTTOM, new Rectangle(x1, y2, iw, _cY));
				atlas.addRegion(usePrefix + LEFT, new Rectangle(x0, y1, _cX, ih));
				atlas.addRegion(usePrefix + RIGHT, new Rectangle(x2, y1, _cX, ih));
				
				atlas.addRegion(usePrefix + CENTER, new Rectangle(x1, y1, iw, ih));

				atlas.addRegion(usePrefix, region);
			}
			
			return new NineSliceBatch(_width, _height, _cX, _cY, _atlasFile, _atlasImgName, _atlasXMLName, usePrefix);
		}
			
		private function updateX():void
		{
			mTopLeft.x = mLeft.x = mBottomLeft.x = 0;
			mTop.x = mCenter.x = mBottom.x = mCx;
			mTopRight.x = mRight.x = mBottomRight.x = mWidth - mCx;
		}
		
		private function updateY():void
		{
			mTop.y = mTopLeft.y = mTopRight.y = 0;
			mLeft.y = mCenter.y = mRight.y = mCy;
			mBottomLeft.y = mBottom.y = mBottomRight.y = mHeight - mCy;
		}
		
		private function updateWidth():void
		{
			mTopLeft.width = mLeft.width = mBottomLeft.width = mCx;
			mTop.width = mCenter.width = mBottom.width = mWidth - 2 * mCx;
			mTopRight.width = mRight.width = mBottomRight.width = mCx;
		}
		
		private function updateHeight():void
		{
			mTop.height = mTopLeft.height = mTopRight.height = mCy;
			mLeft.height = mCenter.height = mRight.height = mHeight - 2 * mCy;
			mBottomLeft.height = mBottom.height = mBottomRight.height = mCy;
		}
		
		public function adjustSizes(newWidth:Number, newHeight:Number, newCx:Number, newCy:Number):void
		{
			mWidth = newWidth;
			mHeight = newHeight;
			mCx = newCx;
			mCy = newCy;
			
			updateX();
			updateY();
			updateWidth();
			updateHeight();
		}
		
		public function adjustUsedSlices(useTopLeft:Boolean = true, useTop:Boolean = true, useTopRight:Boolean = true,
                                         useLeft:Boolean = true, useCenter:Boolean = true, useRight:Boolean = true,
                                         useBottomLeft:Boolean = true, useBottom:Boolean = true, useBottomRight:Boolean = true):void
		{
			this.reset();
			if (useTopLeft) addImage(mTopLeft);
			if (useTop) addImage(mTop);
			if (useTopRight) addImage(mTopRight);
			if (useLeft) addImage(mLeft);
			if (useCenter) addImage(mCenter);
			if (useRight) addImage(mRight);
			if (useBottomLeft) addImage(mBottomLeft);
			if (useBottom) addImage(mBottom);
			if (useRight) addImage(mBottomRight);
		}
	}

}