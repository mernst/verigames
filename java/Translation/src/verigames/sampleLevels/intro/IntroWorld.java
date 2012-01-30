package verigames.sampleLevels.intro;

import verigames.level.Level;
import verigames.level.World;
import verigames.level.WorldXMLPrinter;

public class IntroWorld
{
   public static World getWorld()
   {
      World w = new World();
      
      Level first = FirstLevel.makeLevel();
      first.finishConstruction();
      w.addLevel("First", first);
      
      Level second = SecondLevel.makeLevel();
      second.finishConstruction();
      w.addLevel("Second", second);

      Level third = ThirdLevel.makeLevel();
      third.finishConstruction();
      w.addLevel("Third", third);

      return w;
   }

   public static void main(String[] args)
   {
      new WorldXMLPrinter().print(getWorld(), System.out, null);
   }
}
