package verigames.optimizer.passes;

import org.testng.annotations.Test;
import verigames.level.Board;
import verigames.level.Chute;
import verigames.level.Intersection;
import verigames.level.Level;
import verigames.level.World;
import verigames.optimizer.Util;
import verigames.optimizer.model.NodeGraph;

import java.util.ArrayList;
import java.util.Collection;

public class ConnectorCompressionTest {

    final boolean[] bools = { true, false };

    /**
     * Connectors should be compressed in the expected way
     */
    @Test
    public void testConnectorCompression1() {
        Board board = new Board();
        Intersection start = board.addNode(Intersection.Kind.INCOMING);
        Intersection connect = board.addNode(Intersection.Kind.CONNECT);
        board.add(start, "1", connect, "1", Util.mutableChute());
        board.add(connect, "2", Intersection.Kind.OUTGOING, "1", Util.mutableChute());
        board.finishConstruction();
        Level level = new Level();
        level.addBoard("board", board);
        level.finishConstruction();
        World world = new World();
        world.addLevel("level", level);
        world.validateSubboardReferences();
        NodeGraph g = new NodeGraph(world);

        new ConnectorCompression().optimize(g);

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
        board.add(connect, "5", merge, "6", Util.mutableChute());
        board.add(merge, "7", Intersection.Kind.OUTGOING, "8", Util.mutableChute());
        board.finishConstruction();
        Level level = new Level();
        level.addBoard("board", board);
        level.finishConstruction();
        World world = new World();
        world.addLevel("level", level);
        world.validateSubboardReferences();
        NodeGraph g = new NodeGraph(world);

        new ConnectorCompression().optimize(g);

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
        board.add(merge, "7", Intersection.Kind.OUTGOING, "8", Util.mutableChute());
        board.finishConstruction();
        Level level = new Level();
        level.addBoard("board", board);
        level.finishConstruction();
        World world = new World();
        world.addLevel("level", level);
        world.validateSubboardReferences();
        NodeGraph g = new NodeGraph(world);

        new ConnectorCompression().optimize(g);

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

    public Collection<Chute> allChuteCombos() {
        Collection<Chute> result = new ArrayList<>();
        for (boolean narrow : bools) {
            for (boolean pinched : bools) {
                for (boolean editable : bools) {
                    for (boolean buzzsaw : bools) {
                        Chute chute = new Chute();
                        chute.setEditable(editable);
                        chute.setNarrow(narrow);
                        chute.setPinched(pinched);
                        chute.setBuzzsaw(buzzsaw);
                        result.add(chute);
                    }
                }
            }
        }
        return result;
    }

    /**
     * Test merging for wide & immutable edges
     */
    @Test
    public void mergeWithWideImmutable() {

        ConnectorCompression compress = new ConnectorCompression();

        Chute wide = Util.immutableChute();
        wide.setPinched(false);
        wide.setNarrow(false);

        boolean[] bools = { true, false };
        for (Chute chute : allChuteCombos()) {
            for (boolean swapped : bools) {
                Chute merged = swapped ?
                        compress.compressChutes(chute, wide):
                        compress.compressChutes(wide, chute);

                // for debugging
                System.out.println(chute + " ---> " + merged);

                assert merged != null;
                assert chute.isEditable() || merged.isNarrow() == chute.isNarrow();
                assert merged.isEditable() == chute.isEditable();
                assert merged.hasBuzzsaw() == chute.hasBuzzsaw();
                assert merged.isPinched() == (chute.isPinched() && !(chute.isNarrow() && !chute.isEditable()));
            }
        }

    }

    /**
     * Test merging for narrow & immutable edges
     */
    @Test
    public void mergeWithNarrowImmutable() {
        ConnectorCompression compress = new ConnectorCompression();
        Chute narrow = Util.immutableChute();
        narrow.setPinched(false);
        narrow.setNarrow(true);
        for (Chute chute : allChuteCombos()) {
            for (boolean swapped : bools) {
                Chute merged = swapped ?
                        compress.compressChutes(chute, narrow):
                        compress.compressChutes(narrow, chute);

                // for debugging
                System.out.println(chute + " ---> " + merged);

                assert merged != null;
                assert !merged.isEditable();
                assert merged.isNarrow();
                assert merged.hasBuzzsaw() == chute.hasBuzzsaw();
                assert !merged.isPinched();
            }
        }
    }

}
