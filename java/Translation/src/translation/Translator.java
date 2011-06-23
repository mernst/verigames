package translation;

import java.io.*;
import levelBuilder.LevelBuilder;
import levelBuilder.BoardBuilder;
import com.sun.source.tree.*;

/**
 * @author Nathaniel Mote
 * @author Stephanie Dietzel
 * 
 * This is the class responsible for translating Classes (in the form of
 * ClassTrees) into Levels
 * 
 */

public class Translator
{
   
   public static void translate(ClassTree c, PrintStream out)
   {
      LevelBuilder lb = new LevelBuilder();
      TranslationVisitor visitor = new TranslationVisitor();
   }
}
