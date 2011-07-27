package level;

import java.io.PrintStream;
import java.util.LinkedHashMap;
import java.util.Map;

// TODO update documentation

/**
 * A Set of Levels that make up a world.
 * 
 * @author Nathaniel Mote
 * 
 */

public class World
{
   private final Map<String, Level> nameToLevel;
   
   public World()
   {
      nameToLevel = new LinkedHashMap<String, Level>();
   }
   
   public void addLevel(String name, Level level)
   {
      nameToLevel.put(name, level);
   }
   
   /**
    * Prints the XML for this World<br/>
    * <br/>
    * Requires:<br/>
    * For all Levels l in this, !l.isActive();<br/>
    * out is open<br/>
    */
   public void outputXML(PrintStream out)
   {
      out.println("<?xml version=\"1.0\"?>");
      out.println("<!DOCTYPE world SYSTEM \"world.dtd\">");
      out.println("<world>");
      for (Level l : nameToLevel.values())
         l.outputXML(out);
      out.println("</world>");
   }
   
}
