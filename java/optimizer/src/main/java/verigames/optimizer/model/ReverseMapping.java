package verigames.optimizer.model;

import verigames.level.Board;
import verigames.level.Chute;
import verigames.level.Level;
import verigames.level.World;

import java.io.BufferedWriter;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.OutputStreamWriter;
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
     * (in which case {@link #isMapped} is true and {@link #chuteID} points
     * to the correct chute ID) or it maps to a specific width (in which
     * case {@link #isMapped} is false and {@link #narrow} indicates whether
     * the chute should be narrow or not).
     */
    public static class Mapping {
        public static Mapping NARROW = new Mapping(true);
        public static Mapping WIDE = new Mapping(false);
        public final int chuteID;
        public final boolean narrow;
        public final boolean isMapped;
        public Mapping(int chuteID) {
            this.isMapped = true;
            this.chuteID = chuteID;
            this.narrow = false;
        }
        public Mapping(boolean narrow) {
            this.isMapped = false;
            this.chuteID = 0;
            this.narrow = narrow;
        }

        @Override
        public boolean equals(Object o) {
            if (this == o) return true;
            if (o == null || getClass() != o.getClass()) return false;
            Mapping mapping = (Mapping) o;
            if (chuteID != mapping.chuteID) return false;
            if (isMapped != mapping.isMapped) return false;
            if (narrow != mapping.narrow) return false;
            return true;
        }

        @Override
        public int hashCode() {
            int result = chuteID;
            result = 31 * result + (narrow ? 1 : 0);
            result = 31 * result + (isMapped ? 1 : 0);
            return result;
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
                writer.write(entry.getKey() + " chute " + m.chuteID + "\n");
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
        if (unoptimized == optimized)
            return;
        mapEdge(unoptimized.getUID(), optimized.getUID());
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
        forceWide(unoptimized.getUID());
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
        forceNarrow(unoptimized.getUID());
    }

    protected void forceNarrow(int unoptimizedID) {
        mapping.put(unoptimizedID, Mapping.NARROW);
    }

    private Map<Integer, Chute> chutes(World w) {
        Map<Integer, Chute> chutesByID = new HashMap<>();
        for (Level level : w.getLevels().values()) {
            for (Board board : level.getBoards().values()) {
                for (Chute chute : board.getEdges()) {
                    chutesByID.put(chute.getUID(), chute);
                }
            }
        }
        return chutesByID;
    }

    /**
     * For an edge ID on the original unoptimized world, figure out what
     * it maps to on the optimized world.
     * @param unoptimizedID the unoptimized edge ID
     * @return the optimized edge ID
     */
    public Mapping map(int unoptimizedID) {
        Mapping result = new Mapping(unoptimizedID);
        while (result.isMapped && mapping.containsKey(result.chuteID))
            result = mapping.get(result.chuteID);
        return result;
    }

    /**
     * Convert a solution on the optimized world to a solution on the
     * unoptimized world.
     * @param unoptimized  [IN/OUT] the unoptimized world to solve
     * @param optimized    the already solved optimized world
     */
    public void apply(World unoptimized, World optimized) throws MismatchException {
        Map<Integer, Chute> unoptimizedChutesByID = chutes(unoptimized);
        Map<Integer, Chute> optimizedChutesByID = chutes(optimized);
        for (Integer unoptimizedID : unoptimizedChutesByID.keySet()) {
            Mapping mapping = map(unoptimizedID);
            Chute dst = unoptimizedChutesByID.get(unoptimizedID);

            if (mapping.isMapped) {
                Chute src = optimizedChutesByID.get(mapping.chuteID);
                if (src == null) {
                    throw new MismatchException("Chute " + mapping.chuteID + " was expected in optimized world, but was not found!");
                }
                if (dst == null) {
                    throw new MismatchException("Chute " + mapping.chuteID + " was expected in unoptimized world, but was not found!");
                }
                dst.setNarrow(src.isNarrow());
                dst.setBuzzsaw(src.hasBuzzsaw());
            } else {
                dst.setNarrow(mapping.narrow);
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

}
