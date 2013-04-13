package assets
{
	public class AssetsFont
	{
		[Embed(source="../../lib/assets/font/Patagonia.ttf", fontFamily="Patagonia", embedAsCFF="false", mimeType="application/x-font")] private static const FontPatagonia:Class;
		[Embed(source="../../lib/assets/font/BEBAS___.TTF", fontFamily="Bebas", embedAsCFF="false", mimeType="application/x-font")] private static const FontBebas:Class;
		
		public static const FONT_DEFAULT:String = "Patagonia";
		public static const FONT_NUMERIC:String = "Bebas";
	}
}
