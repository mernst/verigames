package level.tests.levelWorldCreation;

import java.util.HashMap;
import java.util.Map;

import level.Chute;
import level.Level;

public abstract class LevelMaker
{
   
   protected Map<String, Chute> fieldToChute;
   
   protected Level level;
   
   public LevelMaker()
   {
      level = new Level();
      fieldToChute = new HashMap<String, Chute>();
      makeLevel();
   }
   
   protected abstract void makeLevel();
   
   public Level getLevel()
   {
      return level;
   }
}
