package verigames.optimizer;

import org.testng.annotations.Test;
import verigames.level.Board;
import verigames.level.Chute;
import verigames.level.Intersection;
import verigames.level.Level;
import verigames.level.World;
import verigames.optimizer.model.NodeGraph;

public class OptimizerTest {

    static Chute immutableChute() {
        Chute result = new Chute();
        result.setEditable(false);
        return result;
    }

    private Chute mutableChute() {
        Chute result = new Chute();
        result.setEditable(true);
        return result;
    }

    /**
     * In ordinary cases, isolated immutable components
     * should be removed.
     */
    @Test
    public void testIsolatedComponentRemoval() {
        Board board = new Board();
        Intersection start = board.addNode(Intersection.Kind.INCOMING);
        board.add(start, "1", Intersection.Kind.OUTGOING, "2", mutableChute());
        board.add(Intersection.Kind.START_LARGE_BALL, "1", Intersection.Kind.END, "2", immutableChute());
        board.finishConstruction();
        Level level = new Level();
        level.addBoard("board", board);
        level.finishConstruction();
        World world = new World();
        world.addLevel("level", level);
        world.validateSubboardReferences();
        NodeGraph g = new NodeGraph(world);

        new Optimizer().removeIsolatedComponents(g);

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
        board.add(start, "1", Intersection.Kind.OUTGOING, "2", immutableChute());
        board.finishConstruction();
        Level level = new Level();
        level.addBoard("board", board);
        level.finishConstruction();
        World world = new World();
        world.addLevel("level", level);
        world.validateSubboardReferences();
        NodeGraph g = new NodeGraph(world);

        new Optimizer().removeIsolatedComponents(g);

        World finalWorld = g.toWorld();
        assert finalWorld.getLevels().size() == 1;

        Level finalLevel = Util.first(finalWorld.getLevels().values());
        assert finalLevel.getBoards().size() == 1;

        Board finalBoard = Util.first(finalLevel.getBoards().values());
        assert finalBoard.getNodes().size() == 2;
        assert finalBoard.getEdges().size() == 1;
    }

    /**
     * Connectors should be compressed in the expected way
     */
    @Test
    public void testConnectorCompression1() {
        Board board = new Board();
        Intersection start = board.addNode(Intersection.Kind.INCOMING);
        Intersection connect = board.addNode(Intersection.Kind.CONNECT);
        board.add(start, "1", connect, "1", mutableChute());
        board.add(connect, "2", Intersection.Kind.OUTGOING, "1", mutableChute());
        board.finishConstruction();
        Level level = new Level();
        level.addBoard("board", board);
        level.finishConstruction();
        World world = new World();
        world.addLevel("level", level);
        world.validateSubboardReferences();
        NodeGraph g = new NodeGraph(world);

        new Optimizer().compressConnectors(g);

        World finalWorld = g.toWorld();
        assert finalWorld.getLevels().size() == 1;

        Level finalLevel = Util.first(finalWorld.getLevels().values());
        assert finalLevel.getBoards().size() == 1;

        Board finalBoard = Util.first(finalLevel.getBoards().values());
        assert finalBoard.getNodes().size() == 2;
        for (Intersection node : finalBoard.getNodes()) {
            assert node.getIntersectionKind() != Intersection.Kind.CONNECT;
        }

        assert finalBoard.getEdges().size() == 1;
        for (Chute chute : finalBoard.getEdges()) {
            assert chute.isEditable();
        }
    }

    /**
     * Connector compression should NOT remove edges that belong to
     * an edge set.
     */
    @Test
    public void testConnectorCompression2() {
        Board board = new Board();
        Intersection start = board.addNode(Intersection.Kind.INCOMING);
        Intersection merge = board.addNode(Intersection.Kind.MERGE);
        Intersection connect = board.addNode(Intersection.Kind.CONNECT);

        // 2 chutes in the same edge set
        Chute c1 = new Chute(3, "?");
        Chute c2 = new Chute(3, "?");

        board.add(start, "1", connect, "2", c1);
        board.add(start, "3", merge, "4", c2);
        board.add(connect, "5", merge, "6", mutableChute());
        board.add(merge, "7", Intersection.Kind.OUTGOING, "8", mutableChute());
        board.finishConstruction();
        Level level = new Level();
        level.addBoard("board", board);
        level.finishConstruction();
        World world = new World();
        world.addLevel("level", level);
        world.validateSubboardReferences();
        NodeGraph g = new NodeGraph(world);

        new Optimizer().compressConnectors(g);

        World finalWorld = g.toWorld();
        assert finalWorld.getLevels().size() == 1;

        Level finalLevel = Util.first(finalWorld.getLevels().values());
        assert finalLevel.getBoards().size() == 1;

        Board finalBoard = Util.first(finalLevel.getBoards().values());
        assert finalBoard.getNodes().size() == 4;
        assert finalBoard.getEdges().size() == 4;
    }

    /**
     * Connector compression SHOULD compress edges that belong to the
     * same edge set.
     */
    @Test
    public void testConnectorCompression3() {
        Board board = new Board();
        Intersection start = board.addNode(Intersection.Kind.INCOMING);
        Intersection merge = board.addNode(Intersection.Kind.MERGE);
        Intersection connect = board.addNode(Intersection.Kind.CONNECT);

        // 2 chutes in the same edge set
        Chute c1 = new Chute(3, "?");
        Chute c2 = new Chute(3, "?");
        Chute c3 = new Chute(3, "?");

        board.add(start, "1", connect, "2", c1);
        board.add(start, "3", merge, "4", c2);
        board.add(connect, "5", merge, "6", c3);
        board.add(merge, "7", Intersection.Kind.OUTGOING, "8", mutableChute());
        board.finishConstruction();
        Level level = new Level();
        level.addBoard("board", board);
        level.finishConstruction();
        World world = new World();
        world.addLevel("level", level);
        world.validateSubboardReferences();
        NodeGraph g = new NodeGraph(world);

        new Optimizer().compressConnectors(g);

        World finalWorld = g.toWorld();
        assert finalWorld.getLevels().size() == 1;

        Level finalLevel = Util.first(finalWorld.getLevels().values());
        assert finalLevel.getBoards().size() == 1;

        Board finalBoard = Util.first(finalLevel.getBoards().values());
        assert finalBoard.getNodes().size() == 3;
        for (Intersection node : finalBoard.getNodes()) {
            assert node.getIntersectionKind() != Intersection.Kind.CONNECT;
        }

        assert finalBoard.getEdges().size() == 3;
    }

}
