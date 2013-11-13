package verigames.optimizer.passes;

import org.testng.annotations.Test;
import verigames.level.Board;
import verigames.level.Chute;
import verigames.level.Intersection;
import verigames.level.Level;
import verigames.level.World;
import verigames.optimizer.Util;
import verigames.optimizer.model.MismatchException;
import verigames.optimizer.model.Node;
import verigames.optimizer.model.NodeGraph;
import verigames.optimizer.model.Port;
import verigames.optimizer.model.ReverseMapping;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collection;
import java.util.List;

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

        new ConnectorCompression().optimize(g, new ReverseMapping());

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
            assert !chute.isEditable(); // everything is conflict-free
        }
    }

    /**
     * Connector compression should NOT remove edges that belong to
     * an edge set.
     */
    @Test
    public void testConnectorCompression2() {
        System.out.println("cc2");
        Board board = new Board();
        Intersection start = board.addNode(Intersection.Kind.INCOMING);
        Intersection merge = board.addNode(Intersection.Kind.MERGE);
        Intersection connect = board.addNode(Intersection.Kind.CONNECT);

        // 2 chutes in the same edge set
        Chute c1 = new Chute(3, "?");
        Chute c2 = new Chute(3, "?");

        // 2 more chutes in the same edge set
        Chute c3 = new Chute(4, "?");
        Chute c4 = new Chute(4, "?");

        board.add(start, "1", connect, "2", c1);
        board.add(start, "3", merge, "4", c2);
        board.add(connect, "5", merge, "6", c3);
        board.add(merge, "7", Intersection.Kind.OUTGOING, "8", c4);
        board.finishConstruction();
        Level level = new Level();
        level.addBoard("board", board);
        level.finishConstruction();
        World world = new World();
        world.addLevel("level", level);
        world.validateSubboardReferences();
        NodeGraph g = new NodeGraph(world);

        new ConnectorCompression().optimize(g, new ReverseMapping());

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

        // 3 chutes in the same edge set
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

        new ConnectorCompression().optimize(g, new ReverseMapping());

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


    /**
     * Regression test for an odd bug
     */
    @Test
    public void testConnectorCompression4() {

        // Input:
        //                   1
        //    Start  ---------------->  End
        //         \                    /
        //          ----> connector ----
        //           2               3
        //     where:
        //        1 is immutable wide
        //        2 is immutable narrow
        //        3 is mutable wide
        //
        // Expected output:
        //                   1
        //    Start  ---------------->  End
        //         \                    /
        //          -------------------
        //                   2
        //     where:
        //        1 is immutable wide
        //        2 is immutable narrow

        Board board = new Board();
        Intersection start = board.addNode(Intersection.Kind.INCOMING);
        Intersection connect = board.addNode(Intersection.Kind.CONNECT);
        Intersection end = board.addNode(Intersection.Kind.OUTGOING);

        Chute narrowImmutable = Util.immutableChute();
        narrowImmutable.setNarrow(true);

        Chute wideEditable = Util.mutableChute();
        wideEditable.setNarrow(false);
        wideEditable = wideEditable.copy(17, "hello");

        Chute wideImmutable = Util.immutableChute();
        wideImmutable.setNarrow(false);

        board.add(start, "1", connect, "2", narrowImmutable);
        board.add(connect, "3", end, "4", wideEditable);
        board.add(start, "5", end, "6", wideImmutable);
        Level level = new Level();
        level.addBoard("board", board);
        World world = new World();
        world.addLevel("level", level);
        world.finishConstruction();

        NodeGraph g = new NodeGraph(world);

        new ConnectorCompression().optimize(g, new ReverseMapping());

        World finalWorld = g.toWorld();
        assert finalWorld.getLevels().size() == 1;

        Level finalLevel = Util.first(finalWorld.getLevels().values());
        assert finalLevel.getBoards().size() == 1;

        Board finalBoard = Util.first(finalLevel.getBoards().values());
        assert finalBoard.getNodes().size() == 2;
        for (Intersection node : finalBoard.getNodes()) {
            assert node.getIntersectionKind() != Intersection.Kind.CONNECT;
        }

        assert finalBoard.getEdges().size() == 2;
        List<Chute> chutes = new ArrayList<>(finalBoard.getEdges());
        assert chutes.get(0).isNarrow() ^ chutes.get(1).isNarrow(); // 1 narrow, 1 wide
        for (Chute chute : chutes) {
            assert !chute.isEditable();
            assert chute.getVariableID() < 0;
        }
    }

    private int varID = 0;
    private Collection<Chute> allChuteCombos() {
        Collection<Chute> result = new ArrayList<>();
        for (boolean narrow : bools) {
            for (boolean pinched : bools) {
                for (boolean editable : bools) {
                    for (boolean buzzsaw : bools) {
                        int id = editable ? (varID++) : -1;
                        Chute chute = new Chute(id, "no description");
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
     * Make a graph that looks like
     * <pre>
     *     incoming -------> connector --------> outgoing
     *                 1                   2
     * </pre>
     * Where (1) is the given incoming chute and (2) is the
     * given outgoing chute.
     * @param incoming the incoming chute
     * @param outgoing the outgoing chute
     * @return a complete graph
     */
    private NodeGraph mkGraph(Chute incoming, Chute outgoing) {
        NodeGraph g = new NodeGraph();
        Intersection i = Intersection.factory(Intersection.Kind.INCOMING);
        Intersection c = Intersection.factory(Intersection.Kind.CONNECT);
        Intersection o = Intersection.factory(Intersection.Kind.OUTGOING);
        Node in = new Node(null, null, null, null, i);
        Node cn = new Node(null, null, null, null, c);
        Node on = new Node(null, null, null, null, o);
        g.addEdge(in, Port.OUTPUT, cn, Port.INPUT, incoming);
        g.addEdge(cn, Port.OUTPUT, on, Port.INPUT, outgoing);
        return g;
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
                NodeGraph g = swapped ? mkGraph(chute, wide) : mkGraph(wide, chute);
                Chute merged = swapped ?
                        compress.compressChutes(chute, wide, g):
                        compress.compressChutes(wide, chute, g);

                // for debugging
                System.out.println(chute + " ---> " + merged);

                assert merged != null;
                assert chute.isEditable() || merged.isNarrow() == chute.isNarrow();
                assert Util.conflictFree(g, chute) ? !merged.isEditable() : merged.isEditable() == chute.isEditable();
                assert merged.hasBuzzsaw() == chute.hasBuzzsaw();
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
                        compress.compressChutes(chute, narrow, mkGraph(chute, narrow)):
                        compress.compressChutes(narrow, chute, mkGraph(narrow, chute));

                // for debugging
                System.out.println(chute + " ---> " + merged);

                assert merged != null;
                assert !merged.isEditable();
                assert merged.isNarrow();
                assert merged.hasBuzzsaw() == chute.hasBuzzsaw();
            }
        }
    }

    private boolean fitsLargeBall(Chute chute) {
        return chute.hasBuzzsaw() || !chute.isNarrow();
    }

    /**
     * Test the key invariant of connector compression: if a wide ball can
     * flow down the compressed pipe, then it can flow down the two real
     * chutes.
     */
    @Test
    public void testFullCompression() throws MismatchException {
        ConnectorCompression compression = new ConnectorCompression();
        for (Chute tmp1 : allChuteCombos()) {
            for (Chute tmp2 : allChuteCombos()) {

                // ugh, gotta copy the chutes since they know and remember
                // when we add them to boards
                Chute chute1 = tmp1.copy(tmp1.isEditable() ? 1 : -1, "x");
                Chute chute2 = tmp2.copy(tmp2.isEditable() ? 2 : -1, "y");

                // Assemble a world
                Board board = new Board();
                Intersection start = board.addNode(Intersection.Kind.INCOMING);
                Intersection connect = board.addNode(Intersection.Kind.CONNECT);
                Intersection outgoing = board.addNode(Intersection.Kind.OUTGOING);
                board.add(start, "1", connect, "2", chute1);
                board.add(connect, "3", outgoing, "4", chute2);
                Level level = new Level();
                level.addBoard("board", board);
                World world = new World();
                world.addLevel("level", level);
                world.finishConstruction();

                // Optimize the world
                NodeGraph g = new NodeGraph(world);
                ReverseMapping mapping = new ReverseMapping();
                compression.optimize(g, mapping);
                World optimizedWorld = g.toWorld();

                // find all the chutes in the optimized world
                Collection<Chute> optimizedChutes = new ArrayList<>();
                for (Level l : optimizedWorld.getLevels().values()) {
                    for (Board b : level.getBoards().values()) {
                        optimizedChutes.addAll(b.getEdges());
                    }
                }

                // player makes all the mutable edges in the optimized
                // world narrow
                for (Chute c : optimizedChutes) {
                    if (c.isEditable())
                        c.setNarrow(true);
                }

                // translate this back to the original world
                System.out.println("-----");
                System.out.println(Arrays.asList(chute1, chute2));
                System.out.println(optimizedChutes);
                System.out.println(mapping);
                mapping.apply(world, optimizedWorld);

                // figure out if there are "conflicts" (we'll just assume
                // that our incoming node drops large balls)
                boolean noConflict = true;
                for (Chute c : optimizedChutes) {
                    noConflict = noConflict && fitsLargeBall(c);
                }

                if (noConflict) {
                    // verify that if there are NO conflicts in the optimized
                    // world, then there are NO conflicts in the unoptimized one
                    assert fitsLargeBall(chute1);
                    assert fitsLargeBall(chute2);
                } else {
                    // verify that if there ARE conflicts in the optimized
                    // world, then there ARE conflicts in the unoptimized one
                    assert !fitsLargeBall(chute1) || !fitsLargeBall(chute2);
                }

                // player makes all the mutable edges in the optimized
                // world wide
                for (Chute c : optimizedChutes) {
                    if (c.isEditable())
                        c.setNarrow(false);
                }

                // translate this back to the original world
                mapping.apply(world, optimizedWorld);

                // figure out if there are "conflicts" (we'll just assume
                // that our incoming node drops large balls)
                noConflict = true;
                for (Chute c : optimizedChutes) {
                    noConflict = noConflict && fitsLargeBall(c);
                }

                if (noConflict) {
                    // verify that if there are NO conflicts in the optimized
                    // world, then there are NO conflicts in the unoptimized one
                    assert fitsLargeBall(chute1);
                    assert fitsLargeBall(chute2);
                } else {
                    // verify that if there ARE conflicts in the optimized
                    // world, then there ARE conflicts in the unoptimized one
                    assert !fitsLargeBall(chute1) || !fitsLargeBall(chute2);
                }

            }
        }
    }

}
