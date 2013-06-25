package verigames.layout;

import checkers.util.PluginUtil;
import verigames.graph.Edge;
import verigames.level.*;

import java.io.BufferedWriter;
import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
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
  public static void layout(World w, String folder) {
    for (Level l : w.getLevels().values()) {
      for (Map.Entry<String, Board> entry : l.getBoards().entrySet()) {
        String name = entry.getKey();
        final int maxLength = 70;

        if(name.length() > maxLength) {    //TODO JB: FIGURE OUT A BETTER NAME COMPRESSION
            name = name.substring(name.length() - maxLength, name.length());
        }

        System.out.println(name.length() + " Writing " + name);

        Board b = entry.getValue();
        layout(name, b, folder);
      }
    }
  }

  private static void layout(String boardName, Board b, String folder) {
    printBoardVariables(boardName, b, folder);

    AbstractDotPrinter printer = new DotPrinter();
    String command = "dot -Tsvg -o " + folder + "/" + boardName + ".svg";
    AbstractDotParser parser = new StubParser();
    GraphvizRunner runner = new GraphvizRunner(printer, command, parser);
    runner.run(b);
  }

  private static class StubParser extends AbstractDotParser {
    @Override
    public GraphInformation parse(String dotOutput) {
      return null;
    }
  }

  private static void printBoardVariables(final String boardName, final Board b, final String folder) {
      try {
          final File outputTxt = new File(folder, boardName);
          final BufferedWriter bw = new BufferedWriter(new FileWriter(outputTxt));
          bw.write("Nodes: \n");
          for(final Intersection isect : b.getNodes())  {
              bw.write(isect.toString());
              bw.newLine();
          }

          bw.write("\nEdges: \n");
          for( final Edge edge : b.getEdges() ) {
              bw.write(edge.toString());
              bw.newLine();
          }

          bw.flush();
          bw.close();

      } catch (IOException e) {
          throw new RuntimeException(e);
      }
  }
}
