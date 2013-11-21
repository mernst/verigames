package verigames.optimizer.model;

import verigames.level.Board;
import verigames.level.Chute;
import verigames.level.Intersection;
import verigames.level.Level;
import verigames.level.World;
import verigames.utilities.MultiMap;

import java.io.BufferedWriter;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.io.OutputStreamWriter;
import java.io.Writer;
import java.nio.charset.Charset;
import java.util.Collection;
import java.util.Date;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Scanner;
import java.util.Set;
import java.util.regex.Pattern;

/**
 * This class is used to track optimizations made to a world. It can be used
 * to convert a solution on an optimized world to a solution on the original
 * board.
 *
 * <p>
 * To function correctly, all you need to do is call one of the following for
 * every removed edge in the unoptimized world:
 * <ul>
 *     <li>{@link #mapEdge(NodeGraph, Edge, Edge)}</li>
 *     <li>{@link #forceWide(Edge)}</li>
 *     <li>{@link #forceNarrow(Edge)}</li>
 * </ul>
 * You will also want to call {@link #mapBuzzsaw(Edge, Edge)} when
 * appropriate to ensure that buzzsaws are transferred correctly.
 * </p>
 * <p>
 * It is OK if the unoptimized chute wasn't present in the original
 * world (i.e. if you are removing an edge that the optimizer introduced
 * earlier). This class will sort that out, as long as there is a widthMapping from
 * that edge to one in the optimized world.
 * </p>
 */
public class ReverseMapping {

    /**
     * Character set used for reading/writing
     */
    public static final Charset CHARSET = Charset.forName("ascii");

    /**
     * Represents what a chute can map to. Either it maps to another chute
     * (in which case {@link #edge} pointsto the correct edge) or it maps
     * to a specific value (in which case {@link #edge} is null and
     * {@link #val} contains the value). Mappings are used for translating
     * both widths and buzzsaws.
     */
    public static class Mapping {
        public static Mapping TRUE = new Mapping(true);
        public static Mapping FALSE = new Mapping(false);
        public final EdgeID edge;
        public final boolean val;
        public Mapping(EdgeID edge) {
            this.edge = edge;
            this.val = false;
        }
        public Mapping(boolean val) {
            this.edge = null;
            this.val = val;
        }

        @Override
        public boolean equals(Object o) {
            if (this == o) return true;
            if (o == null || getClass() != o.getClass()) return false;
            Mapping mapping = (Mapping) o;
            if (!edge.equals(mapping.edge)) return false;
            if (val != mapping.val) return false;
            return true;
        }

        @Override
        public int hashCode() {
            int result = edge.hashCode();
            result = 31 * result + (val ? 1 : 0);
            return result;
        }

        @Override
        public String toString() {
            if (edge != null)
                return "chute " + edge;
            return val ? "true" : "false";
        }
    }

    /**
     * Width mappings for each chute. {@code val} means "is narrow".
     */
    private final Map<EdgeID, Mapping> widthMapping;

    /**
     * Buzzsaw mappings for each chute {@code val} means "has buzzsaw".
     */
    private final Map<EdgeID, Mapping> buzzsawMapping;

    public ReverseMapping() {
        widthMapping = new HashMap<>();
        buzzsawMapping = new HashMap<>();
    }

    private static void loadMap(Scanner scanner, Map<EdgeID, Mapping> map) throws IOException {
        int size = scanner.nextInt();
        for (int i = 0; i < size; ++i) {
            EdgeID unopt = loadEdge(scanner);
            String type = scanner.next();
            switch (type) {
                case "chute":
                    map.put(unopt, new Mapping(loadEdge(scanner)));
                    break;
                case "true":
                    map.put(unopt, Mapping.TRUE);
                    break;
                case "false":
                    map.put(unopt, Mapping.FALSE);
            }
        }
    }

    private static EdgeID loadEdge(Scanner scanner) {
        int srcID = scanner.nextInt();
        String srcPort = loadStr(scanner);
        int dstID = scanner.nextInt();
        String dstPort = loadStr(scanner);
        return new EdgeID(srcID, srcPort, dstID, dstPort);
    }

    public static ReverseMapping load(InputStream stream) throws IOException {
        Scanner scanner = new Scanner(new InputStreamReader(stream, CHARSET));
        scanner.nextLine(); // drop the comment line at the top
        ReverseMapping map = new ReverseMapping();
        loadMap(scanner, map.widthMapping);
        loadMap(scanner, map.buzzsawMapping);
        return map;
    }

    private static String loadStr(Scanner scanner) {
        int len = scanner.nextInt();
        scanner.skip(" ");
        if (len == 0)
            return "";
        Pattern p = Pattern.compile("(.|\\s){" + len + "}");
        return scanner.next(p);
    }

    private static void exportStr(Writer writer, String s) throws IOException {
        writer.write(Integer.toString(s.length()));
        writer.write(' ');
        writer.write(s);
    }

    private static void exportEdge(Writer writer, EdgeID e) throws IOException {
        writer.write(Integer.toString(e.src));
        writer.write(' ');
        exportStr(writer, e.srcPort);
        writer.write(' ');
        writer.write(Integer.toString(e.dst));
        writer.write(' ');
        exportStr(writer, e.dstPort);
    }

    private static void exportMap(Writer writer, Map<EdgeID, Mapping> map) throws IOException {
        writer.write(map.size() + "\n");
        for (Map.Entry<EdgeID, Mapping> entry : map.entrySet()) {
            Mapping m = entry.getValue();
            exportEdge(writer, entry.getKey());
            if (m.edge != null) {
                writer.write(" chute ");
                exportEdge(writer, m.edge);
                writer.write("\n");
            } else {
                writer.write(" " + (m.val ? "true" : "false") + "\n");
            }
        }
    }

    public void export(OutputStream output) throws IOException {
        BufferedWriter writer = new BufferedWriter(new OutputStreamWriter(output, CHARSET));
        writer.write("# this is an automatically generated verigames optimizer mapping file, created on " + new Date() + "\n");
        exportMap(writer, widthMapping);
        exportMap(writer, buzzsawMapping);
        writer.flush();
    }

    public boolean hasWidthMapping(Chute c) {
        return widthMapping.containsKey(new EdgeID(c));
    }

    public boolean hasWidthMapping(Edge e) {
        return widthMapping.containsKey(new EdgeID(e));
    }

    public boolean hasBuzzsawMapping(Edge e) {
        return buzzsawMapping.containsKey(new EdgeID(e));
    }

    /**
     * Indicate that the given edge in the unoptimized world should assume the
     * value of the given edge in the optimized world once a solution is
     * obtained. Has no effect if the unoptimized argument is immutable.
     * @param g            the graph being optimized
     *                     (does not need to contain the given edges)
     * @param unoptimized  the edge in the unoptimized world
     * @param optimized    the edge in the optimized world
     */
    public void mapEdge(NodeGraph g, Edge unoptimized, Edge optimized) {
        // immutable edges can't map to anything
        if (!unoptimized.isEditable())
            return;
        // by default, edges in the same edge set will do the right thing
        if (g.areLinked(unoptimized, optimized))
            return;
        mapEdge(new EdgeID(unoptimized), new EdgeID(optimized));
    }

    protected void mapEdge(EdgeID unoptimized, EdgeID optimized) {
        // we get this for free
        if (unoptimized.equals(optimized))
            return;
        widthMapping.put(unoptimized, new Mapping(optimized));
    }

    /**
     * Indicate that the given edge in the unoptimized world should have a
     * buzzsaw if and only if the given edge in the optimized world has one.
     * @param unoptimized  the edge in the unoptimized world
     * @param optimized    the edge in the optimized world
     */
    public void mapBuzzsaw(Edge unoptimized, Edge optimized) {
        mapBuzzsaw(new EdgeID(unoptimized), new EdgeID(optimized));
    }

    protected void mapBuzzsaw(EdgeID unoptimized, EdgeID optimized) {
        // we get this for free
        if (unoptimized.equals(optimized))
            return;
        buzzsawMapping.put(unoptimized, new Mapping(optimized));
    }

    /**
     * The given chute must be made wide in the solution.
     * Has no effect if the unoptimized argument is immutable.
     *
     * <p>NOTE: either the given chute must not be linked to any
     * other edges, or you must forceWide all the edges in its
     * edge set.
     * @param unoptimized a chute in the unoptimized world
     */
    public void forceWide(Edge unoptimized) {
        forceNarrow(unoptimized, false);
    }

    /**
     * The given chute must be made narrow in the solution.
     * Has no effect if the unoptimized argument is immutable.
     *
     * <p>NOTE: either the given chute must not be linked to any
     * other edges, or you must forceNarrow all the edges in its
     * edge set.
     * @param unoptimized a chute in the unoptimized world
     */
    public void forceNarrow(Edge unoptimized) {
        forceNarrow(unoptimized, true);
    }

    /**
     * Force the given chute to be narrow or wide in the solution.
     * Has no effect if the unoptimized argument is immutable.
     *
     * <p>NOTE: either the given chute must not be linked to any
     * other edges, or you must forceNarrow all the edges in its
     * edge set to the same value.
     * @param unoptimized a chute in the unoptimized world
     * @param narrow      true to force to narrow, false to force
     *                    to wide
     */
    public void forceNarrow(Edge unoptimized, boolean narrow) {
        // immutable edges can't map to anything
        if (!unoptimized.isEditable())
            return;
        forceNarrow(new EdgeID(unoptimized), narrow);
    }

    /**
     * Used for testing only.
     */
    protected void forceNarrow(Chute unoptimized, boolean narrow) {
        // immutable edges can't map to anything
        if (!unoptimized.isEditable())
            return;
        forceNarrow(new EdgeID(unoptimized), narrow);
    }

    protected void forceNarrow(EdgeID unoptimized, boolean narrow) {
        widthMapping.put(unoptimized, narrow ? Mapping.TRUE : Mapping.FALSE);
    }

    private MultiMap<Integer, Chute> chutesByVarID(World w) {
        MultiMap<Integer, Chute> chutesByID = new MultiMap<>();
        for (Chute chute : w.getChutes()) {
            chutesByID.put(chute.getVariableID(), chute);
        }
        return chutesByID;
    }

    protected static Map<Integer, Intersection> intersectionsByID(World w) {
        Map<Integer, Intersection> map = new HashMap<>();
        for (Level l : w.getLevels().values()) {
            for (Board b : l.getBoards().values()) {
                for (Intersection i : b.getNodes()) {
                    map.put(i.getUID(), i);
                }
            }
        }
        return map;
    }

    protected static Chute findChute(Map<Integer, Intersection> intersectionsByID, World w, EdgeID e) throws MismatchException {
        Intersection src = intersectionsByID.get(e.src);
        if (src == null)
            throw new MismatchException("Missing intersection " + e.src);
        Chute chute = src.getOutput(e.srcPort);
        if (chute == null)
            throw new MismatchException("Intersection " + e.src + " has no output port " + e.srcPort);
        if (!chute.getEndPort().equals(e.dstPort))
            throw new MismatchException("Chute " + chute.getUID() + " destination port is " + chute.getEndPort() + "; should be " + e.dstPort);
        if (chute.getEnd().getUID() != e.dst)
            throw new MismatchException("Chute " + chute.getUID() + " destination intersection is " + chute.getEnd().getUID() + "; should be " + e.dst);
        return chute;
    }

    protected Mapping getWidthMapping(EdgeID e) {
        return map(widthMapping, e);
    }

    protected Mapping getBuzzsawMapping(EdgeID e) {
        return map(buzzsawMapping, e);
    }

    protected Mapping map(Map<EdgeID, Mapping> m, Chute c) {
        return map(m, new EdgeID(c));
    }

    /**
     * For a chute on the original unoptimized world, figure out what it maps
     * to on the optimized world.
     * @param map the map to search
     * @param unoptimized the unoptimized chute
     * @return the mapping, or null if there is none (this usually means that
     * it does not matter what width the edge maps to)
     */
    protected static Mapping map(Map<EdgeID, Mapping> map, EdgeID unoptimized) {
        Mapping result = map.get(unoptimized);
        if (result == null)
            return null;
        while (result.edge != null && map.containsKey(result.edge)) {
            result = map.get(result.edge);
        }
        return result;
    }

    /**
     * Do a bunch of assertions to make sure everything is OK. This is a
     * sanity-check method and when everything is stable we can probably
     * remove it. It is intended to be called after optimization and before
     * you write the optimized world and this mapping to disk.
     * @param unoptimized  the unoptimized world
     * @param optimized    the optimized world
     * @throws AssertionError when something is very wrong
     */
    public void check(World unoptimized, World optimized) {
        Collection<Set<Chute>> unoptimizedEdgeSets = unoptimized.getLinkedChutes();
        Map<Integer, Intersection> optimizedIntersectionsByID = intersectionsByID(optimized);
        for (Set<Chute> chutes : unoptimizedEdgeSets) {
            // check that each edge set is mapped to at MOST one possible thing
            Set<Object> mappings = new HashSet<>();
            for (Chute c : chutes) {
                Mapping width = map(widthMapping, c);
                if (width != null) {
                    assert c.isEditable();
                    if (width.edge != null) {
                        try {
                            Chute target = findChute(optimizedIntersectionsByID, optimized, width.edge);
                            mappings.add(optimized.getLinkedVarIDs(target.getVariableID()));
                        } catch (MismatchException e) {
                            // hm, deleted edge? no problem.
                        }
                    } else {
                        mappings.add(width.val);
                    }
                }
            }
            if (mappings.size() > 1) {
                Set<Integer> vs = new HashSet<>();
                for (Chute c : chutes)
                    vs.add(c.getVariableID());
                System.err.println("Problematic mapping: " + vs + " => " + mappings);
            }
            assert mappings.size() <= 1;
        }
    }

    public Edge findEdge(NodeGraph g, Map<Integer, Node> nodesByID, EdgeID id) {
        Node start = nodesByID.get(id.src);
        if (start == null)
            return null;
        Collection<Edge> outgoing = g.outgoingEdges(start);
        for (Edge e : outgoing) {
            if (new EdgeID(e).equals(id))
                return e;
        }
        return null;
    }

    /**
     * Given an optimized world and its solution, get a solution for the unoptimized version.
     * @param unoptimizedGraph   the unoptimized graph
     * @param optimizedGraph     the optimized graph
     * @param optimizedSolution  the solution for the optimized graph
     * @return a solution for the unoptimized graph
     * @throws MismatchException when this mapping does not properly apply to the given graphs
     */
    public Solution solutionForUnoptimized(
            NodeGraph unoptimizedGraph,
            NodeGraph optimizedGraph,
            Solution optimizedSolution) throws MismatchException {

        Map<Integer, Node> optimizedNodesByID = new HashMap<>();
        for (Node n : optimizedGraph.getNodes()) {
            optimizedNodesByID.put(n.getIntersection().getUID(), n);
        }

        Solution result = new Solution();

        for (Collection<Edge> edgeSet : unoptimizedGraph.getEdgeSets()) {
            boolean narrow = false;
            loop:
            for (Edge e : edgeSet) {
                if (!e.isEditable())
                    continue;
                EdgeID id = new EdgeID(e);
                Mapping m = getWidthMapping(id);
                if (m == null) {
                    for (Edge optEdge : optimizedGraph.edgeSet(e.getVariableID())) {
                        if (optimizedSolution.isNarrow(optEdge)) {
                            narrow = true;
                            break loop;
                        }
                    }
                } else {
                    if (m.edge != null) {
                        Edge optEdge = findEdge(optimizedGraph, optimizedNodesByID, m.edge);
                        if (optimizedSolution.isNarrow(optEdge)) {
                            narrow = true;
                            break;
                        }
                    } else {
                        if (m.val) {
                            narrow = true;
                            break;
                        }
                    }
                }
            }
            for (Edge e : edgeSet) {
                if (e.isEditable())
                    result.setNarrow(e, narrow);
            }
        }

        for (Edge unOpt : unoptimizedGraph.getEdges()) {
            EdgeID id = new EdgeID(unOpt);
            Mapping m = getBuzzsawMapping(id);
            if (m == null) {
                m = new Mapping(id);
            }
            if (m.edge != null) {
                result.setBuzzsaw(unOpt, optimizedSolution.hasBuzzsaw(findEdge(optimizedGraph, optimizedNodesByID, m.edge)));
            } else {
                result.setBuzzsaw(unOpt, m.val);
            }
        }

        return result;
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        ReverseMapping that = (ReverseMapping) o;
        return widthMapping.equals(that.widthMapping) &&
                buzzsawMapping.equals(that.buzzsawMapping);
    }

    @Override
    public int hashCode() {
        return widthMapping.hashCode() * 31 + buzzsawMapping.hashCode();
    }

    @Override
    public String toString() {
        return widthMapping.toString() + ", " + buzzsawMapping.toString();
    }

}
