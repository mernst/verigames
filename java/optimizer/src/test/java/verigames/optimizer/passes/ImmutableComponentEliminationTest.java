package verigames.optimizer.passes;

import org.testng.annotations.Test;
import verigames.level.Board;
import verigames.level.Chute;
import verigames.level.Intersection;
import verigames.level.Level;
import verigames.level.World;
import verigames.optimizer.Util;
import verigames.optimizer.model.NodeGraph;
import verigames.optimizer.model.ReverseMapping;

@Test
public class ImmutableComponentEliminationTest {

    /**
     * In ordinary cases, isolated immutable components
     * should be removed.
     */
    @Test
    public void testIsolatedComponentRemoval() {
        Board board = new Board();
        Intersection start = board.addNode(Intersection.Kind.INCOMING);
        board.add(start, "1", Intersection.Kind.OUTGOING, "2", Util.mutableChute());
        board.add(Intersection.Kind.START_LARGE_BALL, "1", Intersection.Kind.END, "2", Util.immutableChute());
        board.finishConstruction();
        Level level = new Level();
        level.addBoard("board", board);
        level.finishConstruction();
        World world = new World();
        world.addLevel("level", level);
        world.validateSubboardReferences();
        NodeGraph g = new NodeGraph(world);

        new ImmutableComponentElimination().optimize(g, new ReverseMapping());

        World finalWorld = g.toWorld();
        assert finalWorld.getLevels().size() == 1;

        Level finalLevel = Util.first(finalWorld.getLevels().values());
        assert finalLevel.getBoards().size() == 1;

        Board finalBoard = Util.first(finalLevel.getBoards().values());
        assert finalBoard.getNodes().size() == 2;
        for (Intersection node : finalBoard.getNodes()) {
            assert node.getIntersectionKind() != Intersection.Kind.START_LARGE_BALL;
            assert node.getIntersectionKind() != Intersection.Kind.END;
        }

        assert finalBoard.getEdges().size() == 1;
        for (Chute chute : finalBoard.getEdges()) {
            assert chute.isEditable();
        }
    }

    /**
     * Components containing an INCOMING node should NOT
     * be removed.
     */
    @Test
    public void inputNodesArePreserved() {
        Board board = new Board();
        Intersection start = board.addNode(Intersection.Kind.INCOMING);
        board.add(start, "1", Intersection.Kind.OUTGOING, "2", Util.immutableChute());
        board.finishConstruction();
        Level level = new Level();
        level.addBoard("board", board);
        level.finishConstruction();
        World world = new World();
        world.addLevel("level", level);
        world.validateSubboardReferences();
        NodeGraph g = new NodeGraph(world);

        new ImmutableComponentElimination().optimize(g, new ReverseMapping());

        World finalWorld = g.toWorld();
        assert finalWorld.getLevels().size() == 1;

        Level finalLevel = Util.first(finalWorld.getLevels().values());
        assert finalLevel.getBoards().size() == 1;

        Board finalBoard = Util.first(finalLevel.getBoards().values());
        assert finalBoard.getNodes().size() == 2;
        assert finalBoard.getEdges().size() == 1;
    }

}
