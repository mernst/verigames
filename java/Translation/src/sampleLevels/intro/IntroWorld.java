package sampleLevels.intro;

import level.World;
import level.Level;
import level.WorldXMLPrinter;

public class IntroWorld
{
   public static World getWorld()
   {
      World w = new World();
      
      Level first = FirstLevel.makeLevel();
      first.deactivate();
      w.addLevel("First", first);
      
      Level second = SecondLevel.makeLevel();
      second.deactivate();
      w.addLevel("Second", second);

      Level third = ThirdLevel.makeLevel();
      third.deactivate();
      w.addLevel("Third", third);

      return w;
   }

   public static void main(String[] args)
   {
      new WorldXMLPrinter().print(getWorld(), System.out, null);
   }
}
