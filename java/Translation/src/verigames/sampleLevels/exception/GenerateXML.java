package verigames.sampleLevels.exception;

import verigames.layout.WorldLayout;
import verigames.level.World;
import verigames.level.WorldXMLPrinter;

/**
 * Provides a top-level application that generates the XML for the intro World
 * and prints it to standard out.
 *
 * @author Nathaniel Mote
 */

public class GenerateXML
{
  public static void main(String[] args)
  {
    World w = ExceptionWorld.getWorld();
    WorldLayout.layout(w);

    (new WorldXMLPrinter()).print(w, System.out, null);
  }
}
