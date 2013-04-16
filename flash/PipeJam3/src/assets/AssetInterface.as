package assets
{
    import com.emibap.textureAtlas.DynamicAtlas;
	import flash.display.BitmapData;
	import flash.geom.Point;
	import flash.geom.Rectangle;
    
    import flash.display.Bitmap;
    import flash.display.MovieClip;
    import flash.media.Sound;
    import flash.utils.ByteArray;
    import flash.utils.Dictionary;
    import flash.utils.getDefinitionByName;
    import flash.utils.getQualifiedClassName;
    
    import starling.text.BitmapFont;
    import starling.text.TextField;
    import starling.textures.Texture;
    import starling.textures.TextureAtlas;
	
    public class AssetInterface
    {
        // If you're developing a game for the Flash Player / browser plugin, you can directly
        // embed all textures directly in this class. This demo, however, provides two sets of
        // textures for different resolutions. That's useful especially for mobile development,
        // where you have to support devices with different resolutions.
        //
        // For that reason, the actual embed statements are in separate files; one for each
        // set of textures. The correct set is chosen depending on the "contentScaleFactor".
        
        // Texture cache
        
        public static var sContentScaleFactor:int = 1;
        private static var sTextures:Dictionary = new Dictionary();
        private static var sSounds:Dictionary = new Dictionary();
        private static var sTextureAtlas:TextureAtlas;
        private static var sBitmapFontsLoaded:Boolean;
		
		//need to declare a variable of each type, else they get stripped by the compiler and dynamic generation doesn't work
		private var gameAssetEmbeds_1x:GameAssetEmbeds_1x;
		private var gameAssetEmbeds_2x:GameAssetEmbeds_2x;
		private var gameControlPanelssetEmbeds_1x:GameControlPanelAssetEmbeds_1x;
		private var gameControlPanelAssetEmbeds_2x:GameControlPanelAssetEmbeds_2x;
		private var pipeViewPanelAssetEmbeds_1x:PipeViewPanelAssetEmbeds_1x;
		private var pipeViewPanelAssetEmbeds_2x:PipeViewPanelAssetEmbeds_2x;
		private var worldMapAssetEmbeds_1x:WorldMapAssetEmbeds_1x;
		private var worldMapAssetEmbeds_2x:WorldMapAssetEmbeds_2x;
		private var loginAssetEmbeds_1x:LoginAssetEmbeds_1x;
		private var loginAssetEmbeds_2x:LoginAssetEmbeds_2x;
        
        public static function getTexture(file:String, name:String):Texture
        {
            if (sTextures[name] == undefined)
            {
                var data:Object = create(file, name);
                
                if (data is Bitmap)
				{
                    sTextures[name] = Texture.fromBitmap(data as Bitmap, true, false, sContentScaleFactor);
					data = null;
				}
                else if (data is ByteArray)
				{
                    sTextures[name] = Texture.fromAtfData(data as ByteArray, sContentScaleFactor);
					data = null;
				}
				else
				{
					var classInfo:XML = flash.utils.describeType(data);				
					// List the class name.
					trace( "Class " + classInfo.@name.toString());
				}
            }
            
            return sTextures[name];
        }
        
		/**
		 * Similar to getTexture but creates/stores (or retrieves, if already created) bitmap with the given colors replaces, i.e. replace 0xffff0000 with 0xff0000ff
		 * @param	file Name of asset Class
		 * @param	name Name to store/retrieve Texture by, as key to Dictionary of Textures
		 * @param	colorToReplace Color to replace including leading alpha bits i.e. 0xffff0000 (red)
		 * @param	newColor Color to replace previous color with including leading alpha bits i.e. 0xff0000ff (blue)
		 * @return Texture created or retrieved (if already created)
		 */
		public static function getTextureReplaceColor(file:String, name:String, colorToReplace:uint, newColor:uint):Texture
		{
			var newName:String = name + "_" + colorToReplace.toString(16) + "_" + newColor.toString(16);
			if (sTextures[newName] == undefined)
            {
                var data:Object = create(file, name);
                
                if (data is Bitmap)
				{
					var bitmapData:BitmapData = (data as Bitmap).bitmapData;
					// Replace Color
					var maskToUse:uint = 0xffffffff;
					var rect:Rectangle = new Rectangle(0, 0, bitmapData.width, bitmapData.height);
					var p:Point = new Point(0, 0);
					bitmapData.threshold(bitmapData, rect, p, "==", colorToReplace, newColor, maskToUse, true);
					// Color Replaced
					sTextures[newName] = Texture.fromBitmapData(bitmapData, true, false, sContentScaleFactor);
					bitmapData = null;
					data = null;
				}
				else
				{
					var classInfo:XML = flash.utils.describeType(data);				
					// List the class name.
					trace( "Class " + classInfo.@name.toString());
				}
            }
			
			return sTextures[newName];
		}
		
		/**
		 * Similar to getTexture but creates/stores (or retrieves, if already created) bitmap with any non-transparent section replaced with the given color
		 * @param	file Name of asset Class
		 * @param	name Name to store/retrieve Texture by, as key to Dictionary of Textures
		 * @param	color Color to fill the shape with i.e. 0xff0000ff (blue)
		 * @return Texture created or retrieved (if already created)
		 */
		public static function getTextureColorAll(file:String, name:String, color:uint):Texture
		{
			var newName:String = name + "_" + color.toString(16);
			if (sTextures[newName] == undefined)
            {
                var data:Object = create(file, name);
                
                if (data is Bitmap)
				{
					var bitmapData:BitmapData = (data as Bitmap).bitmapData;
					// Replace any non-transparent color with input color
					var maskToUse:uint = 0xffffffff;
					var rect:Rectangle = new Rectangle(0, 0, bitmapData.width, bitmapData.height);
					var p:Point = new Point(0, 0);
					bitmapData.threshold(bitmapData, rect, p, ">=", 0x01000000, color, maskToUse, true);
					// Color Replaced
					sTextures[newName] = Texture.fromBitmapData(bitmapData, true, false, sContentScaleFactor);
					bitmapData = null;
					data = null;
				}
				else
				{
					var classInfo:XML = flash.utils.describeType(data);				
					// List the class name.
					trace( "Class " + classInfo.@name.toString());
				}
            }
			
			return sTextures[newName];
		}
		
        public static function getSound(newName:String):Sound
        {
            var sound:Sound = sSounds[newName] as Sound;
            if (sound) return sound;
            else throw new ArgumentError("Sound not found: " + newName);
        }
        
        public static function getTextureAtlas(file:String, textureFile:String, xmlFile:String):TextureAtlas
        {
            if (sTextureAtlas == null)
            {
                var texture:Texture = getTexture(file, textureFile);
                var xml:XML = XML(create(file, xmlFile));
                sTextureAtlas = new TextureAtlas(texture, xml);
            }
            
            return sTextureAtlas;
        }
        
        public static function loadBitmapFont(filename:String, fontName:String, xmlFile:String):void
        {
            var texture:Texture = getTexture(filename, fontName);
            var xml:XML = XML(create(filename, xmlFile));
            TextField.registerBitmapFont(new BitmapFont(texture, xml));
            sBitmapFontsLoaded = true;
        }
		
		public static function getMovieClipAsTextureAtlas(filename:String, movieClipName:String):TextureAtlas
		{
			var clip:Object = create(filename, movieClipName);
			var atlas:TextureAtlas = DynamicAtlas.fromMovieClipContainer(clip as MovieClip);
			return atlas;
		}
        
        public static function prepareSounds():void
        {
        }
        
        private static function create(file:String, name:String):Object
        {
            var textureClassNameString:String = sContentScaleFactor == 1 ? file+"AssetEmbeds_1x" : file+"AssetEmbeds_2x";
			var qualifiedName:String = "assets." + textureClassNameString;
			var textureClass:Class = getDefinitionByName(qualifiedName) as Class;
			var textureClassObject:Object = (new textureClass) as Object;
            return new textureClassObject[name];
        }
        
        public static function get contentScaleFactor():Number { return sContentScaleFactor; }
        public static function set contentScaleFactor(value:Number):void 
        {
            for each (var texture:Texture in sTextures)
                texture.dispose();
            sTextures = new Dictionary();
            sContentScaleFactor = value < 1.5 ? 1 : 2; // assets are available for factor 1 and 2 
        }
    }
}