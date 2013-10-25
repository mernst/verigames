package verigames.visualizer;

import verigames.level.Board;
import verigames.level.Chute;
import verigames.level.Intersection;
import verigames.level.Level;
import verigames.level.World;

import java.io.PrintStream;
import java.util.HashMap;
import java.util.Map;

public class PrettyDotPrinter {

    private int uid = 0;

    /**
     * Generator for unique IDs. Used for naming edges, nodes, and subgraphs.
     * @return a unique integer
     */
    private int nextUid() {
        return uid++;
    }

    public void print(World world, PrintStream out) {
        out.println("digraph World {");
        for (Map.Entry<String, Level> level : world.getLevels().entrySet()) {
            printLevel(level.getKey(), level.getValue(), out);
        }
        out.println("}");
    }

    private void printLevel(String levelName, Level level, PrintStream out) {
        out.println("subgraph cluster_" + nextUid() + " {");
        out.println("  label = \"level: " + levelName + "\";");
        for (Map.Entry<String, Board> board : level.getBoards().entrySet()) {
            printBoard(board.getKey(), board.getValue(), out);
        }
        out.println("}");
    }

    private void printBoard(String boardName, Board board, PrintStream out) {
        out.println("  subgraph cluster_" + nextUid() + " {");
        out.println("    label = \"board: " + boardName + "\";");
        Map<Intersection, Integer> idsByIntersection = new HashMap<>();
        for (Intersection intersection : board.getNodes()) {
            int id = nextUid();
            idsByIntersection.put(intersection, id);
            out.println("    node" + id + " [" + listProperties(nodeProperties(intersection)) + "];");
        }
        for (Chute chute : board.getEdges()) {
            int srcId = idsByIntersection.get(chute.getStart());
            int dstId = idsByIntersection.get(chute.getEnd());
            out.println("    node" + srcId + " -> node" + dstId + " [" + listProperties(edgeProperties(chute)) + "]");
        }
        out.println("  }");
    }

    private String listProperties(Map<String, String> properties) {
        StringBuilder buf = new StringBuilder();
        boolean first = true;
        for (Map.Entry<String, String> entry : properties.entrySet()) {
            if (!first)
                buf.append(',');
            else
                first = false;
            buf.append(entry.getKey());
            buf.append("=\"");
            buf.append(entry.getValue());
            buf.append("\"");
        }
        return buf.toString();
    }

    private Map<String, String> edgeProperties(Chute chute) {
        Map<String, String> result = new HashMap<>();
        result.put("label", chute.getUID() + (chute.getVariableID() > 0 ? " (var#" + chute.getVariableID() + ")" : ""));
        result.put("penwidth", chute.isNarrow() ? "1" : "5");
        result.put("color", chute.isEditable() ? "black" : "lightgrey");
        return result;
    }

    private Map<String, String> nodeProperties(Intersection intersection) {
        Map<String, String> result = new HashMap<>();
        result.put("label", intersection.getIntersectionKind() == Intersection.Kind.SUBBOARD ?
                "SUBBOARD " + intersection.asSubboard().getSubnetworkName() :
                intersection.getIntersectionKind() + " " + intersection.getUID());
        Intersection.Kind kind = intersection.getIntersectionKind();
        if (kind == Intersection.Kind.SUBBOARD) {
            result.put("style", "filled");
            result.put("fillcolor", "lightgrey");
            result.put("shape", "box");
        } else if (kind == Intersection.Kind.MERGE || kind == Intersection.Kind.SPLIT) {
            result.put("shape", "point");
        }
        return result;
    }

}
