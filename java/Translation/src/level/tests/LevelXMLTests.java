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

// class TestClass
// {
// String s;
//
// public TestClass()
// {
// s = null;
// }
//
// public void method()
// {
// s = new String("asdf");
// }
// }

public class LevelXMLTests
{
   
   /**
    * Generates the XML for the above TestClass
    */
   @Test public void test1() throws FileNotFoundException
   {
      Level l = new Level();
      
      Board constructor = new Board();
      constructor.addNode(new Intersection(Kind.INCOMING));
      Intersection start = new Intersection(Kind.START_BLACK_BALL);
      constructor.addNode(start);
      Intersection outgoing = new Intersection(Kind.OUTGOING);
      constructor.addNode(outgoing);
      Chute c = new Chute("s", false, true, null);
      c.setNarrow(false);
      constructor.addEdge(start, 0, outgoing, 0, c);
      
      l.addBoard("constructor", constructor);
      
      Intersection incoming = new Intersection(Kind.INCOMING);
      Intersection restart = new Intersection(Kind.RESTART_WHITE_BALL);
      Intersection out = new Intersection(Kind.OUTGOING);
      
      Board method = new Board();
      method.addNode(incoming);
      method.addNode(restart);
      method.addNode(out);
      
      Chute c2 = new Chute("s", false, true, null);
      Chute c3 = new Chute("s", false, true, null);
      
      method.addEdge(incoming, 0, restart, 0, c2);
      method.addEdge(restart, 0, outgoing, 0, c3);
      
      l.addBoard("method", method);
      
      Set<Chute> linked = new HashSet<Chute>();
      linked.add(c);
      linked.add(c2);
      linked.add(c3);
      
      l.makeLinked(linked);
      
      PrintStream p = new PrintStream(new FileOutputStream(new File("TestClass.actual.xml")));
      
      l.outputXML(p);
      
   }
}
