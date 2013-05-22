package assets
{
	public class AssetsFont
	{
		[Embed(source="../../lib/assets/font/Vegur-R 0.602.otf", fontFamily="Vegur", embedAsCFF="false", mimeType="application/x-font")] private static const FontVegur:Class;
		[Embed(source="../../lib/assets/font/BEBAS___.TTF", fontFamily="Bebas", embedAsCFF="false", mimeType="application/x-font")] private static const FontBebas:Class;
		[Embed(source="../../lib/assets/font/Denk_One/DenkOne-Regular.ttf", fontFamily="DenkOne", embedAsCFF="false", mimeType="application/x-font")] private static const FontDenkOne:Class;
		[Embed(source="../../lib/assets/font/Metal_Mania/MetalMania-Regular.ttf", fontFamily="MetalMania", embedAsCFF="false", mimeType="application/x-font")] private static const FontMetalMania:Class;
		
		public static const FONT_DEFAULT:String   = "Vegur";
		public static const FONT_FRACTION:String  = "Bebas";
		public static const FONT_NUMERIC:String = "DenkOne";
		public static const FONT_SCORE:String = "MetalMania";
	}
}
