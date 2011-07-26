package level.tests.levelWorldCreation;

import level.Level;
import level.World;

public class LevelWorld
{
   public static World getWorld()
   {
      World levelWorld = new World();
      
      LevelMaker cl = new ChuteLevel();
      Level chuteLevel = cl.getLevel();
      chuteLevel.deactivate();
      levelWorld.add(chuteLevel);
      
      return levelWorld;
   }
}
