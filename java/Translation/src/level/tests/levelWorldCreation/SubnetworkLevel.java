package level.tests.levelWorldCreation;

import static level.Intersection.factory;
import static level.Intersection.Kind.END;
import static level.Intersection.Kind.SPLIT;
import static level.tests.levelWorldCreation.BuildingTools.initializeBoard;

import java.util.LinkedHashMap;
import java.util.Map;

import level.Board;
import level.Chute;
import level.Intersection;
import level.Level;

public class SubnetworkLevel
{
   private static final Map<String, Integer> nameToPortMap;
   static
   {
      nameToPortMap = new LinkedHashMap<String, Integer>();
      nameToPortMap.put("name", 0);
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
            
            Chute top = new Chute("methodName");
            Chute bottom = top.copy();
            constructor.addEdge(incoming, 0, split, 0, top);
            constructor.addEdge(split, 1, end, 0, bottom);
            l.makeLinked(top, bottom);
         }
         
         // make name chute:
         nameChute = new Chute("name");
         constructor.addEdge(split, 0, outgoing, 0, nameChute);
      }
      
      // make getSubnetworkName:
      {
         Board subnetworkName = initializeBoard(l, "Subnetwork.getSubnetworkName");
         
         Intersection incoming = subnetworkName.getIncomingNode();
         Intersection outgoing = subnetworkName.getOutgoingNode();
         
         Intersection split = factory(SPLIT);
         subnetworkName.addNode(split);
         
         Chute top = new Chute("name");
         Chute bottom = top.copy();
         subnetworkName.addEdge(incoming, 0, split, 0, top);
         subnetworkName.addEdge(split, 0, outgoing, 0, bottom);
         l.makeLinked(top, bottom, nameChute);
         
         subnetworkName.addEdge(split, 1, outgoing, 1, new Chute(null));
      }
      
      return l;
   }
}
