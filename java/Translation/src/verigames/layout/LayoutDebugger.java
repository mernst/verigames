package verigames.layout;

import verigames.level.*;

import java.util.*;

/**
 * Supports faster debugging of game graphs by outputting Graphviz-generated
 * PNGs for the boards in a world for inspection.
 */
public class LayoutDebugger
{
  /**
   * Writes PNGs with the layout for the given world to the given folder. The
   * folder must already exist.
   */
  // TODO it would probably be useful to subclass DotPrinter to include more
  // metadata with the game graph.
  public static void layout(World w, String folder)
  {
    for (Level l : w.getLevels().values())
    {
      for (Map.Entry<String, Board> entry : l.getBoards().entrySet())
      {
        String name = entry.getKey();
        Board b = entry.getValue();
        layout(name, b, folder);
      }
    }
  }

  private static void layout(String boardName, Board b, String folder)
  {
    AbstractDotPrinter printer = new DotPrinter();
    String command = "dot -Tpng -o " + folder + "/" + boardName + ".png";
    AbstractDotParser parser = new StubParser();
    GraphvizRunner runner = new GraphvizRunner(printer, command, parser);
    runner.run(b);
  }

  private static class StubParser extends AbstractDotParser
  {
    @Override
    public GraphInformation parse(String dotOutput)
    {
      return null;
    }
  }
}
