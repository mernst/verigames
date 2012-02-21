package verigames.sampleLevels.level;

import java.util.LinkedHashMap;
import java.util.Map;

import verigames.level.Level;
import verigames.level.World;



@SuppressWarnings("deprecation")
public class LevelWorld
{
  public static World getWorld()
  {
    World levelWorld = new World();
    
    for (Map.Entry<String, Level> e : getLevels().entrySet())
    {
      e.getValue().finishConstruction();
      levelWorld.addLevel(e.getKey(), e.getValue());
    }
    
    return levelWorld;
  }
  
  private static Map<String, Level> getLevels()
  {
    Map<String, Level> l = new LinkedHashMap<String, Level>();
    
    l.put("Chute", ChuteLevel.makeLevel());
    l.put("Intersection", IntersectionLevel.makeLevel());
    l.put("Board", BoardLevel.makeLevel());
    l.put("Level", LevelLevel.makeLevel());
    l.put("World", WorldLevel.makeLevel());
    l.put("Subnetwork", SubnetworkLevel.makeLevel());
    l.put("NullTest", NullTestLevel.makeLevel());
    
    return l;
  }
}
