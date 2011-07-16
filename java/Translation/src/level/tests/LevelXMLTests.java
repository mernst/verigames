package level.tests;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.PrintStream;
import java.util.HashSet;
import java.util.Set;

import level.Board;
import level.Chute;
import level.Intersection;
import level.Intersection.Kind;
import level.Level;

import org.junit.Test;

public class LevelXMLTests
{
   
   /**
    * Generates the XML for TestClass (below)
    * 
    * class TestClass
    * {
    *    String s;
    *    
    *    public TestClass()
    *    {
    *       s = null;
    *    }
    * 
    *    public void method()
    *    {
    *       s = new String("asdf");
    *    }   
    * }
    */
   @Test public void test1() throws FileNotFoundException
   {
      Level l = new Level();
      
      Board constructor = new Board();
      constructor.addNode(Intersection.factory(Kind.INCOMING));
      Intersection start = Intersection
            .factory(Kind.START_BLACK_BALL);
      constructor.addNode(start);
      Intersection outgoing = Intersection.factory(Kind.OUTGOING);
      constructor.addNode(outgoing);
      Chute c = new Chute("s", false, true, null);
      c.setNarrow(false);
      constructor.addEdge(start, 0, outgoing, 0, c);
      
      l.addBoard("constructor", constructor);
      
      Intersection incoming = Intersection.factory(Kind.INCOMING);
      Intersection end = Intersection.factory(Kind.END);
      Intersection restart = Intersection
            .factory(Kind.START_WHITE_BALL);
      Intersection out = Intersection.factory(Kind.OUTGOING);
      
      Board method = new Board();
      method.addNode(incoming);
      method.addNode(end);
      method.addNode(restart);
      method.addNode(out);
      
      Chute c2 = new Chute("s", false, true, null);
      Chute c3 = new Chute("s", false, true, null);
      
      method.addEdge(incoming, 0, end, 0, c2);
      method.addEdge(restart, 0, out, 0, c3);
      
      l.addBoard("method", method);
      
      Set<Chute> linked = new HashSet<Chute>();
      linked.add(c);
      linked.add(c2);
      linked.add(c3);
      
      l.makeLinked(linked);

      l.deactivate();
      
      PrintStream p = new PrintStream(new FileOutputStream(new File(
            "TestClass.actual.xml")));
      l.outputXML(p);
      p.close();
      
   }
}
