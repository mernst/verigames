package levelBuilder.tests;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.PrintStream;

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
   public void generateBasicXML() throws FileNotFoundException
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
      w.add(TestClass.getLevel());
      
      PrintStream out = new PrintStream(new FileOutputStream(new File("TestClass.actual.xml")));
      
      w.outputXML(out);
      
      out.close();
   }
}
