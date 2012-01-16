package sampleLevels.exception;

import level.Board;
import level.Chute;
import level.Intersection.Kind;
import level.Intersection;
import level.Level;
import level.World;

public class ExceptionWorld
{
   public static World getWorld()
   {
      Level l = new Level();

      Board b = new Board();
      Intersection incoming = Intersection.factory(Kind.INCOMING);
      Intersection outgoing = Intersection.factory(Kind.OUTGOING);
      b.addNode(incoming);
      b.addNode(outgoing);
      
      Intersection start = Intersection.factory(Kind.START_BLACK_BALL);
      Intersection merge = Intersection.factory(Kind.MERGE);
      b.addNode(start);
      b.addNode(merge);

      Chute top = new Chute();
      Chute bottom = top.copy();
      bottom.setPinched(true);
      b.addEdge(incoming, 0, merge, 0, top);
      b.addChuteName(top, "var");
      b.addEdge(merge, 0, outgoing, 0, bottom);
      b.addChuteName(bottom, "var");
      l.makeLinked(top, bottom);

      Chute right = new Chute();
      b.addEdge(start, 0, merge, 1, right);

      l.addBoard("Placeholder", b);
      l.finishConstruction();

      World w = new World();
      w.addLevel("Placeholder", l);

      return w;
   }
}
