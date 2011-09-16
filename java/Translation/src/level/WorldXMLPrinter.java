package level;

import java.io.PrintStream;
import java.util.Map;

import utilities.Printer;

public class WorldXMLPrinter extends Printer<World, Void>
{
   @Override
   protected void printIntro(World toPrint, PrintStream out, Void data)
   {
      out.println("<?xml version=\"1.0\"?>");
      out.println("<!DOCTYPE world SYSTEM \"world.dtd\">");
      out.println("<world>");
   }

   @Override
   protected void printMiddle(World toPrint, PrintStream out, Void data)
   {
      for (Map.Entry<String, Level> entry : toPrint.getLevels().entrySet())
         entry.getValue().outputXML(entry.getKey(), out);
   }

   @Override
   protected void printOutro(World toPrint, PrintStream out, Void data)
   {
      out.println("</world>");
   }
}
