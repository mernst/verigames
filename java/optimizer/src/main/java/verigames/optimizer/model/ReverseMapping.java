package verigames.optimizer.model;

import verigames.level.Board;
import verigames.level.Chute;
import verigames.level.Level;
import verigames.level.World;
import verigames.optimizer.Util;
import verigames.utilities.MultiMap;

import java.io.BufferedWriter;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.OutputStreamWriter;
import java.util.Collection;
import java.util.Date;
import java.util.HashMap;
import java.util.Map;
import java.util.Scanner;

/**
 * This class is used to track optimizations made to a world. It can be used
 * to convert a solution on an optimized world to a solution on the original
 * board.
 *
 * <p>
 * To function correctly, all you need to do is call one of the following for
 * every removed edge in the unoptimized world:
 * <ul>
 *     <li>{@link #mapEdge(verigames.level.Chute, verigames.level.Chute)}</li>
 *     <li>{@link #forceWide(verigames.level.Chute)}</li>
 *     <li>{@link #forceNarrow(verigames.level.Chute)}</li>
 * </ul>
 * It is OK if the unoptimized chute wasn't present in the original
 * world (i.e. if you are removing an edge that the optimizer introduced
 * earlier). This class will sort that out, as long as there is a mapping from
 * that edge to one in the optimized world.
 * </p>
 */
public class ReverseMapping {

    /**
     * Represents what a chute can map to. Either it maps to another chute
     * (in which case {@link #isMapped} is true and {@link #varID} points
     * to the correct variable ID) or it maps to a specific width (in which
     * case {@link #isMapped} is false and {@link #narrow} indicates whether
     * the chute should be narrow or not).
     */
    public static class Mapping {
        public static Mapping NARROW = new Mapping(true);
        public static Mapping WIDE = new Mapping(false);
        public final int varID;
        public final boolean narrow;
        public final boolean isMapped;
        public Mapping(int varID) {
            this.isMapped = true;
            this.varID = varID;
            this.narrow = false;
        }
        public Mapping(boolean narrow) {
            this.isMapped = false;
            this.varID = 0;
            this.narrow = narrow;
        }

        @Override
        public boolean equals(Object o) {
            if (this == o) return true;
            if (o == null || getClass() != o.getClass()) return false;
            Mapping mapping = (Mapping) o;
            if (varID != mapping.varID) return false;
            if (isMapped != mapping.isMapped) return false;
            if (narrow != mapping.narrow) return false;
            return true;
        }

        @Override
        public int hashCode() {
            int result = varID;
            result = 31 * result + (narrow ? 1 : 0);
            result = 31 * result + (isMapped ? 1 : 0);
            return result;
        }

        @Override
        public String toString() {
            if (isMapped)
                return "chute " + varID;
            return narrow ? "narrow" : "wide";
        }
    }

    private final Map<Integer, Mapping> mapping;

    public ReverseMapping() {
        mapping = new HashMap<>();
    }

    public static ReverseMapping load(InputStream stream) throws IOException {
        Scanner scanner = new Scanner(stream);
        scanner.nextLine(); // drop the comment line at the top
        ReverseMapping map = new ReverseMapping();
        int size = scanner.nextInt();
        for (int i = 0; i < size; ++i) {
            int unopt = scanner.nextInt();
            String type = scanner.next();
            switch (type) {
                case "chute":
                    map.mapEdge(unopt, scanner.nextInt());
                    break;
                case "narrow":
                    map.forceNarrow(unopt);
                    break;
                case "wide":
                    map.forceWide(unopt);
            }
        }
        return map;
    }

    public void export(OutputStream output) throws IOException {
        BufferedWriter writer = new BufferedWriter(new OutputStreamWriter(output));
        writer.write("# this is an automatically generated verigames optimizer mapping file, created on " + new Date() + "\n");
        writer.write(mapping.size() + "\n");
        for (Map.Entry<Integer, Mapping> entry : mapping.entrySet()) {
            Mapping m = entry.getValue();
            if (m.isMapped) {
                writer.write(entry.getKey() + " chute " + m.varID + "\n");
            } else {
                writer.write(entry.getKey() + " " + (m.narrow ? "narrow" : "wide") + "\n");
            }
        }
        writer.flush();
    }

    /**
     * Indicate that the given edge in the unoptimized world should assume the
     * value of the given edge in the optimized world once a solution is
     * obtained. Has no effect if the unoptimized argument is immutable.
     * @param unoptimized  the edge in the unoptimized world
     * @param optimized    the edge in the optimized world
     */
    public void mapEdge(Chute unoptimized, Chute optimized) {
        // immutable edges can't map to anything
        if (!unoptimized.isEditable())
            return;
        // by default, edges with the same ID do the right thing
        if (unoptimized.getVariableID() == optimized.getVariableID())
            return;
        mapEdge(unoptimized.getVariableID(), optimized.getVariableID());
    }

    protected void mapEdge(int unoptimizedID, int optimizedID) {
        mapping.put(unoptimizedID, new Mapping(optimizedID));
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
    public void forceWide(Chute unoptimized) {
        // immutable edges can't map to anything
        if (!unoptimized.isEditable())
            return;
        forceWide(unoptimized.getVariableID());
    }

    protected void forceWide(int unoptimizedID) {
        mapping.put(unoptimizedID, Mapping.WIDE);
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
    public void forceNarrow(Chute unoptimized) {
        // immutable edges can't map to anything
        if (!unoptimized.isEditable())
            return;
        forceNarrow(unoptimized.getVariableID());
    }

    protected void forceNarrow(int unoptimizedID) {
        mapping.put(unoptimizedID, Mapping.NARROW);
    }

    private MultiMap<Integer, Chute> chutesByVarID(World w) {
        MultiMap<Integer, Chute> chutesByID = new MultiMap<>();
        for (Level level : w.getLevels().values()) {
            for (Board board : level.getBoards().values()) {
                for (Chute chute : board.getEdges()) {
                    int varID = chute.getVariableID();
                    if (varID >= 0) {
                        chutesByID.put(varID, chute);
                    }
                }
            }
        }
        return chutesByID;
    }

    /**
     * For a var ID on the original unoptimized world, figure out what it maps
     * to on the optimized world.
     * @param unoptimizedID the unoptimized var ID
     * @return the mapping, or null if there is none (this usually means that
     * it does not matter what width the edge maps to)
     */
    public Mapping map(int unoptimizedID) {
        Mapping result = mapping.get(unoptimizedID);
        if (result == null)
            return null;
        while (result.isMapped && mapping.containsKey(result.varID)) {
            result = mapping.get(result.varID);
        }
        return result;
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
        MultiMap<Integer, Chute> unoptimizedChutesByVarID = chutesByVarID(unoptimized);
        MultiMap<Integer, Chute> optimizedChutesByID = chutesByVarID(optimized);
        for (Integer unoptimizedID : unoptimizedChutesByVarID.keySet()) {
            Mapping mapping = map(unoptimizedID);
            Collection<Integer> linkedVarIDs = unoptimized.getLinkedVarIDs(unoptimizedID);

            if (mapping == null) {
                Collection<Chute> srcs = optimizedChutesByID.get(unoptimizedID);
                if (!srcs.isEmpty()) {
                    Chute src = Util.first(srcs);
                    for (Integer varID : linkedVarIDs) {
                        for (Chute chute : unoptimizedChutesByVarID.get(varID)) {
                            chute.setNarrow(src.isNarrow());
                        }
                    }
                }
                continue;
            }

            if (mapping.isMapped) {
                Collection<Chute> srcs = optimizedChutesByID.get(mapping.varID);
                if (srcs.isEmpty()) {
                    throw new MismatchException("Variable ID " + mapping.varID + " was expected in optimized world, but was not found!");
                }
                Chute src = Util.first(srcs);
                for (Integer varID : linkedVarIDs) {
                    for (Chute chute : unoptimizedChutesByVarID.get(varID)) {
                        chute.setNarrow(src.isNarrow());
                        chute.setBuzzsaw(src.hasBuzzsaw());
                    }
                }
            } else {
                for (Integer varID : linkedVarIDs) {
                    for (Chute chute : unoptimizedChutesByVarID.get(varID)) {
                        chute.setNarrow(mapping.narrow);
                    }
                }
            }
        }
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        ReverseMapping that = (ReverseMapping) o;
        return mapping.equals(that.mapping);
    }

    @Override
    public int hashCode() {
        return mapping.hashCode();
    }

    @Override
    public String toString() {
        return mapping.toString();
    }

}
