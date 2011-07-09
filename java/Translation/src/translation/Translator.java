package translation;

import java.io.*;

import javax.lang.model.element.Name;

import level.Chute;
import level.Level;
import levelBuilder.LevelBuilder;
import levelBuilder.BoardBuilder;
import com.sun.source.tree.*;

/**
 * 
 * This is the class responsible for translating Classes (in the form of
 * ClassTrees) into Levels
 * 
 * @author Nathaniel Mote
 * @author Stephanie Dietzel
 */

public class Translator
{
   
   
   public static Level translate(ClassTree c)
   {
      LevelBuilder lb = new LevelBuilder();
      TranslationVisitor visitor = new TranslationVisitor();
      throw new RuntimeException("Not yet implemented");
   }
   
   public static Chute generateChute(VariableTree tree)
   {
      throw new RuntimeException("Not yet implemented");
   }
}
