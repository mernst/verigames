package levelBuilder.tests;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.PrintStream;
import java.util.ArrayList;
import java.util.List;

import level.Chute;
import level.Intersection.Kind;
import level.World;
import levelBuilder.BoardBuilder;
import levelBuilder.LevelBuilder;

import org.junit.Test;

public class LevelBuilderSpecTests
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
   @Test
   public void generateTestClassXML() throws FileNotFoundException
   {
      LevelBuilder TestClass = new LevelBuilder();
      
      TestClass.addField(new Chute("s", true, null));
      
      BoardBuilder constructor = TestClass.getConstructorTemplate("constructor");
      constructor.assignment("s", Kind.START_BLACK_BALL);
      
      TestClass.finishBoardBuilder(constructor);
      
      BoardBuilder method = TestClass.getTemplateBoardBuilder("method");
      method.assignment("s", Kind.START_BLACK_BALL);
      
      TestClass.finishBoardBuilder(method);
      
      World w = new World();
      w.addLevel("TestClass", TestClass.getLevel());
      
      PrintStream out = new PrintStream(new FileOutputStream(new File("TestClass.actual.xml")));
      
      w.outputXML(out);
      
      out.close();
   }
   
   /**
    * Generates the XML for TestClass2 (below)
    * 
    * class TestClass2
    * {
    *    List<String> list;
    *    
    *    public TestClass2()
    *    {
    *       list = new List<String>();
    *    }
    *    
    *    public addElt()
    *    {
    *       list.add("asdf");
    *    }
    * }
    */
   @Test
   public void generateTestClass2XML() throws FileNotFoundException
   {
      LevelBuilder TestClass2 = new LevelBuilder();
      
      List<Chute> auxChutes = new ArrayList<Chute>();
      auxChutes.add(new Chute(null, true, null));
      
      TestClass2.addField(new Chute("list", true, auxChutes));
      
      BoardBuilder constructor = TestClass2.getConstructorTemplate("constructor");
      constructor.assignment("list", Kind.START_WHITE_BALL);
      
      TestClass2.finishBoardBuilder(constructor);
      
      BoardBuilder addElt = TestClass2.getTemplateBoardBuilder("addElt");
      addElt.addPinchToVar("list");
      
      // merge into aux chute somehow
      
      TestClass2.finishBoardBuilder(addElt);
      
      World w = new World();
      w.addLevel("TestClass2", TestClass2.getLevel());
      
      PrintStream out = new PrintStream(new FileOutputStream(new File("TestClass2.actual.xml")));
      
      w.outputXML(out);
      
      out.close();
      
   }
}
