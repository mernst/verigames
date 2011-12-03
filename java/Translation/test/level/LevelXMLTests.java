package level;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.PrintStream;

import level.Board;
import level.Chute;
import level.Intersection;
import level.Intersection.Kind;
import level.Level;
import level.World;
import level.WorldXMLPrinter;

import org.junit.Test;

import sampleLevels.level.LevelWorld;

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
   @Test public void TestClassXML() throws FileNotFoundException
   {
      Level l = new Level();
      
      Board constructor = new Board();
      constructor.addNode(Intersection.factory(Kind.INCOMING));
      Intersection start = Intersection
            .factory(Kind.START_BLACK_BALL);
      constructor.addNode(start);
      Intersection outgoing = Intersection.factory(Kind.OUTGOING);
      constructor.addNode(outgoing);
      Chute c = new Chute();
      c.setNarrow(false);
      constructor.addEdge(start, 0, outgoing, 0, c);
      constructor.addChuteName(c, "s");
      
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
      
      Chute c2 = new Chute();
      Chute c3 = new Chute();
      
      method.addEdge(incoming, 0, end, 0, c2);
      method.addChuteName(c2, "s");
      method.addEdge(restart, 0, out, 0, c3);
      method.addChuteName(c3, "s");
      
      l.addBoard("method", method);
      
      l.makeLinked(c, c2, c3);

      l.deactivate();
      
      World w = new World();
      w.addLevel("TestClass", l);
      
      PrintStream p = new PrintStream(new FileOutputStream(new File(
            "TestClass.actual.xml")));
      new WorldXMLPrinter().print(w, p, null);
      p.close();
   }
   
   /**
    * Outputs the xml for the level package to the file level.actual.xml<br/>
    * <br/>
    * Based on the code at changeset 594f3ec9f9d4<br/>
    * <br/>
    * Contains some optimizations, such as removing checkRep() calls
    */
   @Test public void levelXML() throws FileNotFoundException
   {
      World levelWorld = LevelWorld.getWorld();
      
      PrintStream p = new PrintStream(new FileOutputStream(new File(
            "level.actual.xml")));
      new WorldXMLPrinter().print(levelWorld, p, null);
      p.close();
   }

   /**
    * Outputs the XML for a single board with a black ball merging into a pipe
    * with a pinch-point.<br/>
    * <br/>
    * Useful because it necessitates an exception to the laws of physics.
    */
   @Test
   public void exceptionXML() throws FileNotFoundException
   {
      World w = sampleLevels.exception.ExceptionWorld.getWorld();

      PrintStream p = new PrintStream(new FileOutputStream(new
            File("exception.xml")));
      new WorldXMLPrinter().print(w, p, null);
      p.close();
   }
}
