package verigames.sampleLevels.level;

import static verigames.level.Intersection.factory;
import static verigames.level.Intersection.Kind.END;
import static verigames.level.Intersection.Kind.SPLIT;
import static verigames.utilities.BuildingTools.initializeBoard;

import java.util.LinkedHashMap;
import java.util.Map;

import verigames.level.Board;
import verigames.level.Chute;
import verigames.level.Intersection;
import verigames.level.Level;


@SuppressWarnings("deprecation")
public class SubnetworkLevel
{
  private static final Map<String, String> nameToPortMap;
  static
  {
    nameToPortMap = new LinkedHashMap<String, String>();
    nameToPortMap.put("name", "0");
  }
  
  public static Level makeLevel()
  {
    Level l = new Level();
    
    Chute nameChute;
    
    // make constructor:
    {
      Board constructor = initializeBoard(l, "Subnetwork.constructor");
      
      Intersection incoming = constructor.getIncomingNode();
      Intersection outgoing = constructor.getOutgoingNode();
      
      Intersection split = factory(SPLIT);
      constructor.addNode(split);
      
      // make methodName chutes:
      {
        Intersection end = factory(END);
        constructor.addNode(end);
        
        Chute top = new Chute();
        Chute bottom = top.copy();
        String name = "methodName";
        
        constructor.addEdge(incoming, "0", split, "0", top);
        constructor.addEdge(split, "1", end, "0", bottom);
        constructor.addChuteName(top, name);
        constructor.addChuteName(bottom, name);
        
        l.makeLinked(top, bottom);
      }
      
      // make name chute:
      nameChute = new Chute();
      constructor.addEdge(split, "0", outgoing, "0", nameChute);
      constructor.addChuteName(nameChute, "name");
    }
    
    // make getSubnetworkName:
    {
      Board subnetworkName = initializeBoard(l, "Subnetwork.getSubnetworkName");
      
      Intersection incoming = subnetworkName.getIncomingNode();
      Intersection outgoing = subnetworkName.getOutgoingNode();
      
      Intersection split = factory(SPLIT);
      subnetworkName.addNode(split);
      
      Chute top = new Chute();
      Chute bottom = top.copy();
      String name = "name";
      
      subnetworkName.addEdge(incoming, "0", split, "0", top);
      subnetworkName.addEdge(split, "0", outgoing, "0", bottom);
      subnetworkName.addChuteName(top, name);
      subnetworkName.addChuteName(bottom, name);
      l.makeLinked(top, bottom, nameChute);
      
      subnetworkName.addEdge(split, "1", outgoing, "1", new Chute());
    }
    
    return l;
  }
}
