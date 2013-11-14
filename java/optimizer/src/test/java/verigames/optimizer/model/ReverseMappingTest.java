package verigames.optimizer.model;

import org.testng.annotations.Test;
import verigames.level.Board;
import verigames.level.Chute;
import verigames.level.Intersection;
import verigames.level.Level;
import verigames.level.World;
import verigames.optimizer.Util;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;

public class ReverseMappingTest {

    @Test
    public void testIO() throws IOException {
        ReverseMapping mapping = new ReverseMapping();
        mapping.forceNarrow(1, true);
        mapping.forceNarrow(2, false);
        mapping.mapEdge(3, 4);
        mapping.mapEdge(6, 7);

        ByteArrayOutputStream output = new ByteArrayOutputStream();
        mapping.export(output);

        ReverseMapping mapping2 = ReverseMapping.load(new ByteArrayInputStream(output.toByteArray()));

        assert mapping.equals(mapping2);
    }

    @Test
    public void testApply() throws MismatchException {

        Board board = new Board();
        board.addNode(Intersection.Kind.INCOMING);
        Intersection outgoing = board.addNode(Intersection.Kind.OUTGOING);

        // add some interesting geometry we'll work on
        //   drop1 _
        //          \_________ outgoing
        //         _/ merge
        //   drop2
        Intersection drop1 = board.addNode(Intersection.Kind.START_SMALL_BALL);
        Intersection drop2 = board.addNode(Intersection.Kind.START_SMALL_BALL);
        Intersection merge = board.addNode(Intersection.Kind.MERGE);

        Chute c1 = new Chute(1, "");
        Chute c2 = new Chute(2, "");
        Chute c3 = new Chute(3, "");

        c1.setEditable(true);
        c2.setEditable(true);
        c3.setEditable(true);

        board.addEdge(drop1, "out", merge, "in1", c1);
        board.addEdge(drop2, "out", merge, "in2", c2);
        board.addEdge(merge, "out", outgoing, "in", c3);

        Level level = new Level();
        level.addBoard("board", board);
        World world = new World();
        world.addLevel("level", level);
        world.finishConstruction();

        // --------

        board = new Board();
        Intersection incoming = board.addNode(Intersection.Kind.INCOMING);
        outgoing = board.addNode(Intersection.Kind.OUTGOING);

        // add some interesting geometry we'll work on
        //   incoming -------- outgoing
        Chute optimizedChute = new Chute(4, "");
        optimizedChute.setEditable(false);
        optimizedChute.setNarrow(false);
        optimizedChute.setBuzzsaw(true);

        board.addEdge(incoming, "out", outgoing, "in1", optimizedChute);

        level = new Level();
        level.addBoard("board", board);
        World optimized = new World();
        optimized.addLevel("level", level);
        optimized.finishConstruction();

        // --------

        ReverseMapping mapping = new ReverseMapping();
        mapping.forceNarrow(c1.getVariableID(), true);
        mapping.forceNarrow(c2.getVariableID(), false);
        Chute intermediateChute = new Chute(5, "");
        intermediateChute.setEditable(true);
        mapping.mapEdge(c3.getVariableID(), intermediateChute.getVariableID());
        mapping.mapEdge(intermediateChute.getVariableID(), optimizedChute.getVariableID());

        mapping.apply(world, optimized);
        assert c1.isNarrow();
        assert !c2.isNarrow();
        assert c3.isNarrow() == optimizedChute.isNarrow();
        assert c3.hasBuzzsaw() == optimizedChute.hasBuzzsaw();
    }

    /**
     * Tests this case:
     *
     * <pre>
     * unoptimized
     *    X ---> Y ---> Z
     *       1      1
     *
     * optimized
     *    X ---> Z
     *       1
     *
     * mapping
     *    (empty)
     * </pre>
     *
     * What should happen is that both edges (with var ID = 1) get the same
     * value that the single optimized edge (with var ID = 1) has.
     *
     */
    @Test
    public void testApply2() throws MismatchException {
        Chute c1 = Util.mutableChute().copy(1, "a");
        Chute c2 = Util.mutableChute().copy(1, "b");
        Chute c3 = Util.mutableChute().copy(1, "c");

        c1.setNarrow(true);
        c2.setNarrow(true);
        c3.setNarrow(true);

        Board b1 = new Board();
        Intersection incoming = b1.addNode(Intersection.Kind.INCOMING);
        Intersection connection = b1.addNode(Intersection.Kind.CONNECT);
        b1.add(incoming, "1", connection, "2", c1);
        b1.add(connection, "3", Intersection.Kind.OUTGOING, "4", c2);
        Level l1 = new Level();
        l1.addBoard("b", b1);
        World unoptimized = new World();
        unoptimized.addLevel("l", l1);
        unoptimized.finishConstruction();

        Board b2 = new Board();
        b2.add(Intersection.Kind.INCOMING, "1", Intersection.Kind.OUTGOING, "2", c3);
        Level l2 = new Level();
        l2.addBoard("b", b2);
        World optimized = new World();
        optimized.addLevel("l", l2);
        optimized.finishConstruction();

        c3.setNarrow(false);
        new ReverseMapping().apply(unoptimized, optimized);
        assert c1.isNarrow() == c3.isNarrow();
        assert c2.isNarrow() == c3.isNarrow();

        c3.setNarrow(true);
        new ReverseMapping().apply(unoptimized, optimized);
        assert c1.isNarrow() == c3.isNarrow();
        assert c2.isNarrow() == c3.isNarrow();
    }

}
