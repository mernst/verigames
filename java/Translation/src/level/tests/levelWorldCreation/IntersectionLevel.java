package level.tests.levelWorldCreation;

import level.Board;
import level.Chute;
import level.Intersection;
import level.Intersection.Kind;
import level.Level;

public class IntersectionLevel
{
   public static Level makeLevel()
   {
      Level level = new Level();
      
      addFactory(level);
      
      return level;
   }
   
   private static void addFactory(Level level)
   {
      Board factory = new Board();
      level.addBoard("factory", factory);
      
      Intersection incoming = Intersection.factory(Kind.INCOMING);
      Intersection outgoing = Intersection.factory(Kind.OUTGOING);
      factory.addNode(incoming);
      factory.addNode(outgoing);
      
      Intersection startLeft = Intersection.factory(Kind.START_WHITE_BALL);
      Intersection startRight = Intersection.factory(Kind.START_WHITE_BALL);
      factory.addNode(startLeft);
      factory.addNode(startRight);
      
      Intersection merge = Intersection.factory(Kind.MERGE);
      factory.addNode(merge);
      
      Chute left = new Chute(null, true, null);
      Chute right = new Chute(null, true, null);
      Chute bottom = new Chute(null, true, null);
      
      factory.addEdge(startLeft, 0, merge, 0, left);
      factory.addEdge(startRight, 0, merge, 1, right);
      factory.addEdge(merge, 0, outgoing, 0, bottom);
   }
   
}
