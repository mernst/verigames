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
        mapping.forceNarrow(1);
        mapping.forceWide(2);
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

        Chute c1 = Util.mutableChute();
        Chute c2 = Util.mutableChute();
        Chute c3 = Util.mutableChute();

        board.addEdge(drop1, "out", merge, "in1", c1);
        board.addEdge(drop2, "out", merge, "in2", c2);
        board.addEdge(merge, "out", outgoing, "in", c3);

        board.finishConstruction();
        Level level = new Level();
        level.addBoard("board", board);
        level.finishConstruction();
        World world = new World();
        world.addLevel("level", level);
        world.finishConstruction();

        // --------

        board = new Board();
        Intersection incoming = board.addNode(Intersection.Kind.INCOMING);
        outgoing = board.addNode(Intersection.Kind.OUTGOING);

        // add some interesting geometry we'll work on
        //   incoming -------- outgoing
        Chute optimizedChute = Util.mutableChute();
        optimizedChute.setNarrow(false);
        optimizedChute.setBuzzsaw(true);

        board.addEdge(incoming, "out", outgoing, "in1", optimizedChute);

        board.finishConstruction();
        level = new Level();
        level.addBoard("board", board);
        level.finishConstruction();
        World optimized = new World();
        optimized.addLevel("level", level);
        optimized.finishConstruction();

        // --------

        ReverseMapping mapping = new ReverseMapping();
        mapping.forceNarrow(c1);
        mapping.forceWide(c2);
        Chute intermediateChute = Util.mutableChute();
        mapping.mapEdge(c3, intermediateChute);
        mapping.mapEdge(intermediateChute, optimizedChute);

        mapping.apply(world, optimized);
        assert c1.isNarrow();
        assert !c2.isNarrow();
        assert c3.isNarrow() == optimizedChute.isNarrow();
        assert c3.hasBuzzsaw() == optimizedChute.hasBuzzsaw();
    }

}
