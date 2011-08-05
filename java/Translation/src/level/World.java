package level;

import java.io.PrintStream;
import java.util.LinkedHashMap;
import java.util.Map;

/**
 * A set of ordered pairs of {@link Level}s and names. Each {@link Level} must
 * have a unique name.
 * 
 * @author Nathaniel Mote
 * 
 */

public class World
{
   private final Map<String, Level> nameToLevel;
   
   /**
    * Creates a new, empty {@code World}
    */
   public World()
   {
      nameToLevel = new LinkedHashMap<String, Level>();
   }
   
   /**
    * Adds {@code level} to {@code this}, with {@code name} as its name.
    * 
    * @param level
    * The {@link Level} to add.
    * @param name
    * The name to associate with {@code level}.
    */
   public void addLevel(String name, Level level)
   {
      nameToLevel.put(name, level);
   }
   
   /**
    * Prints the XML for this {@code World}<br/>
    * <br/>
    * Requires:<br/>
    * - For all {@link Level}s {@code l} in {@code this},
    * {@link Level#isActive() !l.isActive()}<br/>
    * - {@code out} is open<br/>
    * 
    * @param out
    * The {@code PrintStream} to which the XML will be printed
    */
   public void outputXML(PrintStream out)
   {
      out.println("<?xml version=\"1.0\"?>");
      out.println("<!DOCTYPE world SYSTEM \"world.dtd\">");
      out.println("<world>");
      for (Map.Entry<String, Level> entry : nameToLevel.entrySet())
         entry.getValue().outputXML(entry.getKey(), out);
      out.println("</world>");
   }
   
}
