package level.tests.levelWorldCreation;

import level.Level;
import level.World;

public class LevelWorld
{
   public static World getWorld()
   {
      World levelWorld = new World();
      
      Level chuteLevel = ChuteLevel.makeLevel();
      chuteLevel.deactivate();
      levelWorld.add(chuteLevel);
      
      return levelWorld;
   }
}
