package layout;

import level.Board;
import level.Level;
import level.World;
import level.WorldXMLPrinter;
import level.levelWorldCreation.IntersectionLevel;
import level.levelWorldCreation.LevelWorld;

public class Test
{
   public static void main (String[] args)
   {
      Layout.main(args);
   }
}

class Layout
{
   public static void main(String[] args)
   {
      World w = LevelWorld.getWorld();
      new WorldLayout().layout(w);
      new WorldXMLPrinter().print(w, System.out, null);
   }
}

class Dot
{
   public static void main(String[] args)
   {
      Board b;
      {
         Level l = IntersectionLevel.makeLevel();
         l.deactivate();
         b = l.getBoard("Intersection.padToLength");
      }
     
      
      DotPrinter p = new DotPrinter();
      
      p.print(b, System.out, null);
   }
}
