package verigames.optimizer.model;

import verigames.level.Board;
import verigames.level.Chute;
import verigames.level.Intersection;
import verigames.level.Level;
import verigames.level.World;
import verigames.optimizer.Util;
import verigames.utilities.MultiMap;

import java.io.BufferedWriter;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.OutputStreamWriter;
import java.io.Writer;
import java.util.Collection;
import java.util.Collections;
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
 * You will also want to call {@link #mapBuzzsaw(NodeGraph, Edge, Edge)} when
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

    protected static class EdgeID {
        public final int src;
        public final String srcPort;
        public final int dst;
        public final String dstPort;

        public EdgeID(int src, String srcPort, int dst, String dstPort) {
            this.src = src;
            this.srcPort = srcPort;
            this.dst = dst;
            this.dstPort = dstPort;
        }

        public EdgeID(Edge e) {
            this(e.getSrc().getIntersection().getUID(),
                    e.getSrcPort().getName(),
                    e.getDst().getIntersection().getUID(),
                    e.getSrcPort().getName());
        }

        public EdgeID(Chute c) {
            this(c.getStart().getUID(),
                    c.getStartPort(),
                    c.getEnd().getUID(),
                    c.getEndPort());
        }

        @Override
        public boolean equals(Object o) {
            if (this == o) return true;
            if (o == null || getClass() != o.getClass()) return false;
            EdgeID edgeID = (EdgeID) o;
            if (dst != edgeID.dst) return false;
            if (src != edgeID.src) return false;
            if (!dstPort.equals(edgeID.dstPort)) return false;
            if (!srcPort.equals(edgeID.srcPort)) return false;
            return true;
        }

        @Override
        public int hashCode() {
            int result = src;
            result = 31 * result + srcPort.hashCode();
            result = 31 * result + dst;
            result = 31 * result + dstPort.hashCode();
            return result;
        }

        @Override
        public String toString() {
            return "EdgeID{" +
                    "src=" + src +
                    ", srcPort='" + srcPort + '\'' +
                    ", dst=" + dst +
                    ", dstPort='" + dstPort + '\'' +
                    '}';
        }

    }

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
        Scanner scanner = new Scanner(stream);
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
        BufferedWriter writer = new BufferedWriter(new OutputStreamWriter(output));
        writer.write("# this is an automatically generated verigames optimizer mapping file, created on " + new Date() + "\n");
        exportMap(writer, widthMapping);
        exportMap(writer, buzzsawMapping);
        writer.flush();
    }

    public boolean hasWidthMapping(EdgeID e) {
        return widthMapping.containsKey(e);
    }

    public boolean hasBuzzsawMapping(EdgeID e) {
        return buzzsawMapping.containsKey(e);
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
        // we get this for free
        if (unoptimized.equals(optimized))
            return;
        // by default, edges in the same edge set will do the right thing
        if (g.areLinked(unoptimized, optimized))
            return;
        mapEdge(new EdgeID(optimized), new EdgeID(unoptimized));
    }

    protected void mapEdge(EdgeID unoptimized, EdgeID optimized) {
        widthMapping.put(unoptimized, new Mapping(optimized));
    }

    /**
     * Indicate that the given edge in the unoptimized world should have a
     * buzzsaw if and only if the given edge in the optimized world has one.
     * @param unoptimized  the edge in the unoptimized world
     * @param optimized    the edge in the optimized world
     */
    public void mapBuzzsaw(NodeGraph g, Edge unoptimized, Edge optimized) {
        // immutable edges can't map to anything
        if (!unoptimized.isEditable())
            return;
        // we get this for free
        if (unoptimized.equals(optimized))
            return;
        // by default, edges in the same edge set will do the right thing
        if (g.areLinked(unoptimized, optimized))
            return;
        mapEdge(new EdgeID(optimized), new EdgeID(unoptimized));
    }

    protected void mapBuzzsaw(EdgeID unoptimized, EdgeID optimized) {
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
    public void forceNarrow(Chute unoptimized, boolean narrow) {
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
        if (!chute.getEndPort().equals(e.dstPort) || chute.getEnd().getUID() != e.dst)
            throw new MismatchException("Missing chute " + e);
        return chute;
    }

    public Mapping mapWidth(Chute c) {
        return map(widthMapping, new EdgeID(c));
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

    private void setWidth(Collection<Chute> chutes, boolean narrow) {
        for (Chute c : chutes) {
            if (c.isEditable())
                c.setNarrow(narrow);
        }
    }

    /**
     * Do a bunch of assertions to make sure everything is OK. This is a
     * sanity-check method and when everything is stable we can probably
     * remove it. It is intended to be called after optimization and before
     * you write the optimized world and this mapping to disk.
     * @param unoptimized  the unoptimized world
     * @param optimized    the optimized world
     */
    public void check(World unoptimized, World optimized) throws MismatchException {
        Collection<Set<Chute>> unoptimizedEdgeSets = unoptimized.getLinkedChutes();
        Map<Integer, Intersection> optimizedIntersectionsByID = intersectionsByID(optimized);
        for (Set<Chute> chutes : unoptimizedEdgeSets) {
            // check that each edge set is mapped to at MOST one possible thing
            Set<Object> mappings = new HashSet<>();
            for (Chute c : chutes) {
                Mapping width = map(widthMapping, c);
                if (width != null) {
                    if (width.edge != null) {
                        Chute target = findChute(optimizedIntersectionsByID, optimized, width.edge);
                        mappings.add(optimized.getLinkedVarIDs(target.getVariableID()));
                    } else {
                        mappings.add(width.val);
                    }
                }
            }
            if (mappings.size() > 1) {
                Set<Integer> vs = new HashSet<>();
                for (Chute c : chutes)
                    vs.add(c.getVariableID());
                Util.logVerbose("Problematic mapping: " + vs + " => " + mappings);
            }
            assert mappings.size() <= 1;
        }
    }

    /**
     * Convert a solution on the optimized world to a solution on the
     * unoptimized world.
     *
     * <p>Precondition: all editable chutes in both worlds have non-negative
     * var IDs. (This is because negative var IDs are treated specially.)
     * @param unoptimized  [IN/OUT] the unoptimized world to solve
     * @param optimized    the already solved optimized world
     */
    public void apply(World unoptimized, World optimized) throws MismatchException {
        Collection<Set<Chute>> unoptimizedChutes = unoptimized.getLinkedChutes();
        MultiMap<Integer, Chute> optimizedChutesByVarID = chutesByVarID(optimized);
        Map<Integer, Intersection> optimizedIntersectionsByID = intersectionsByID(optimized);
        for (Set<Chute> chutes : unoptimizedChutes) {
            // figuring out widths is complicated
            Chute c = Util.first(chutes);
            Mapping mapping = map(widthMapping, c);

            Set<Integer> vs = new HashSet<>();
            for (Chute ch : chutes) {
                vs.add(ch.getVariableID());
            }

            if (mapping == null) { // no widthMapping? copy result from solved world

                // Find some matching variable ID in the optimized world
                Collection<Chute> srcs = Collections.emptySet();
                for (Integer varID : vs) {
                    srcs = optimizedChutesByVarID.get(varID);
                    if (!srcs.isEmpty())
                        break;
                }
                if (srcs.isEmpty()) {
                    continue; // no correspondence? must not matter.
                }
                setWidth(chutes, Util.first(srcs).isNarrow());

            } else if (mapping.edge != null) { // widthMapping? copy result from corresponding chute

                Chute src = findChute(optimizedIntersectionsByID, optimized, mapping.edge);
                setWidth(chutes, src.isNarrow());

            } else { // forced value? set it

                setWidth(chutes, mapping.val);

            }

            // figuring out buzzsaws is easy
            for (Chute chute : chutes) {
                Mapping buzz = map(buzzsawMapping, chute);
                if (buzz != null) {
                    if (buzz.edge != null) {
                        Chute src = findChute(optimizedIntersectionsByID, optimized, buzz.edge);
                        chute.setBuzzsaw(src.hasBuzzsaw());
                    } else {
                        chute.setBuzzsaw(buzz.val);
                    }
                } else {
                    chute.setBuzzsaw(false);
                }
            }
        }
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
