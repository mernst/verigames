package level;

import java.io.PrintStream;
import java.util.LinkedHashSet;

/**
 * A Set of Levels that make up a world.
 * 
 * @author Nathaniel Mote
 * 
 */

public class World extends LinkedHashSet<Level>
{
   
   private static final long serialVersionUID = 8743080574151346401L;
   
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
      for (Level l : this)
         l.outputXML(out);
      out.println("</world>");
   }
   
}
