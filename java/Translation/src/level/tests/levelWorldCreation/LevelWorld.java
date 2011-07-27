package level.tests.levelWorldCreation;

import java.util.ArrayList;
import java.util.Collection;
import java.util.List;

import level.Level;
import level.World;


public class LevelWorld
{
   public static World getWorld()
   {
      World levelWorld = new World();
      
      for (Level l : getLevels())
      {
         l.deactivate();
         levelWorld.add(l);
      }
      
      return levelWorld;
   }
   
   private static Collection<Level> getLevels()
   {
      List<Level> l = new ArrayList<Level>();
      
      //l.add(ChuteLevel.makeLevel());
      //l.add(IntersectionLevel.makeLevel());
      l.add(BoardLevel.makeLevel());
      
      return l;
   }
}
