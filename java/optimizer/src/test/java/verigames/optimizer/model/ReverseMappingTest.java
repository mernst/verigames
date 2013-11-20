package verigames.optimizer.model;

import org.testng.annotations.Test;
import verigames.level.Board;
import verigames.level.Chute;
import verigames.level.Intersection;
import verigames.level.Level;
import verigames.level.World;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

@Test
public class ReverseMappingTest {

    @Test
    public void testWidthMapping() {
        ReverseMapping m = new ReverseMapping();
        EdgeID e1 = new EdgeID(1, "1", 2, "2");
        EdgeID e2 = new EdgeID(1, "1", 2, "3");
        m.mapEdge(e1, e2);
        assert m.getWidthMapping(e1).edge.equals(e2);
        assert m.getWidthMapping(e2) == null;
        assert m.getBuzzsawMapping(e1) == null;
    }

    @Test
    public void testOverwriteWidthMapping() {
        ReverseMapping m = new ReverseMapping();
        EdgeID e1 = new EdgeID(1, "1", 2, "2");
        EdgeID e2 = new EdgeID(1, "1", 2, "3");
        EdgeID e3 = new EdgeID(3, "4", 5, "6");
        m.mapEdge(e1, e2);
        m.mapEdge(e1, e3);
        assert m.getWidthMapping(e1).edge.equals(e3);
        assert m.getWidthMapping(e2) == null;
        assert m.getWidthMapping(e3) == null;
        assert m.getBuzzsawMapping(e1) == null;
    }

    @Test
    public void testChainWidthMapping() {
        ReverseMapping m = new ReverseMapping();
        EdgeID e1 = new EdgeID(1, "1", 2, "2");
        EdgeID e2 = new EdgeID(1, "1", 2, "3");
        EdgeID e3 = new EdgeID(3, "4", 5, "6");
        m.mapEdge(e1, e2);
        m.mapEdge(e2, e3);
        assert m.getWidthMapping(e1).edge.equals(e3);
        assert m.getWidthMapping(e2).edge.equals(e3);
        assert m.getWidthMapping(e3) == null;
        assert m.getBuzzsawMapping(e1) == null;
    }

    @Test
    public void testFixedWidthMapping() {
        ReverseMapping m = new ReverseMapping();
        EdgeID e1 = new EdgeID(1, "1", 2, "2");
        EdgeID e2 = new EdgeID(1, "1", 2, "3");
        m.forceNarrow(e1, true);
        assert m.getWidthMapping(e1).val;
        m.forceNarrow(e1, false);
        assert !m.getWidthMapping(e1).val;
        m.mapEdge(e1, e2);
        m.forceNarrow(e2, true);
        assert m.getWidthMapping(e1).val;
        assert m.getWidthMapping(e2).val;
    }

    @Test
    public void testBuzzsawMapping() {
        ReverseMapping m = new ReverseMapping();
        EdgeID e1 = new EdgeID(1, "1", 2, "2");
        EdgeID e2 = new EdgeID(1, "1", 2, "3");
        m.mapBuzzsaw(e1, e2);
        assert m.getBuzzsawMapping(e1).edge.equals(e2);
        assert m.getBuzzsawMapping(e2) == null;
        assert m.getWidthMapping(e1) == null;
    }

    @Test
    public void testOverwriteBuzzsawMapping() {
        ReverseMapping m = new ReverseMapping();
        EdgeID e1 = new EdgeID(1, "1", 2, "2");
        EdgeID e2 = new EdgeID(1, "1", 2, "3");
        EdgeID e3 = new EdgeID(3, "4", 5, "6");
        m.mapBuzzsaw(e1, e2);
        m.mapBuzzsaw(e1, e3);
        assert m.getBuzzsawMapping(e1).edge.equals(e3);
        assert m.getBuzzsawMapping(e2) == null;
        assert m.getBuzzsawMapping(e3) == null;
        assert m.getWidthMapping(e1) == null;
    }

    @Test
    public void testChainBuzzsawMapping() {
        ReverseMapping m = new ReverseMapping();
        EdgeID e1 = new EdgeID(1, "1", 2, "2");
        EdgeID e2 = new EdgeID(1, "1", 2, "3");
        EdgeID e3 = new EdgeID(3, "4", 5, "6");
        m.mapBuzzsaw(e1, e2);
        m.mapBuzzsaw(e2, e3);
        assert m.getBuzzsawMapping(e1).edge.equals(e3);
        assert m.getBuzzsawMapping(e2).edge.equals(e3);
        assert m.getBuzzsawMapping(e3) == null;
        assert m.getWidthMapping(e1) == null;
    }

    @Test
    public void testBuzzsawTransfer() throws MismatchException {
        ReverseMapping m = new ReverseMapping();

        NodeGraph g = new NodeGraph();
        Node n1 = new Node("a", "b", Intersection.factory(Intersection.Kind.INCOMING));
        Node n2 = new Node("a", "b", Intersection.factory(Intersection.Kind.OUTGOING));
        Edge e = g.addEdge(n1, new Port("1"), n2, new Port("2"), EdgeData.createMutable(1, "desc"));

        Solution x = new Solution();

        x.setBuzzsaw(e, true);
        Solution s1 = m.solutionForUnoptimized(g, g, x);
        assert s1.hasBuzzsaw(e);

        x.setBuzzsaw(e, false);
        Solution s2 = m.solutionForUnoptimized(g, g, x);
        assert !s2.hasBuzzsaw(e);
    }

    @Test
    public void testIO() throws IOException {
        ReverseMapping mapping = new ReverseMapping();

        EdgeID one = new EdgeID(1, "a", 2, "b");
        EdgeID two = new EdgeID(2, "a", 2, "b");
        EdgeID three = new EdgeID(3, "a", 2, "b");
        EdgeID four = new EdgeID(4, "a", 2, "b");
        EdgeID five = new EdgeID(5, "a", 2, "b");
        EdgeID six = new EdgeID(6, "a", 2, "b");

        mapping.forceNarrow(one, true);
        mapping.forceNarrow(two, false);
        mapping.mapEdge(three, four);
        mapping.mapEdge(five, six);

        ByteArrayOutputStream output = new ByteArrayOutputStream();
        mapping.export(output);

        ReverseMapping mapping2 = ReverseMapping.load(new ByteArrayInputStream(output.toByteArray()));

        assert mapping.equals(mapping2);
    }

    private void apply(ReverseMapping m, World unoptimized, World optimized) throws MismatchException {
        m.solutionForUnoptimized(
                new NodeGraph(unoptimized),
                new NodeGraph(optimized),
                new Solution(optimized)).applyTo(unoptimized);
    }

    @Test
    public void testApply() throws MismatchException, IOException {

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
        mapping.forceNarrow(c1, true);
        mapping.forceNarrow(c2, false);
        EdgeID intermediate = new EdgeID(300, "x", 400, "y");
        mapping.mapEdge(new EdgeID(c3), intermediate);
        mapping.mapEdge(intermediate, new EdgeID(optimizedChute));

        mapping.mapBuzzsaw(new EdgeID(c3), intermediate);
        mapping.mapBuzzsaw(intermediate, new EdgeID(optimizedChute));

        apply(mapping, world, optimized);
        assert c1.isNarrow();
        assert !c2.isNarrow();
        assert c3.isNarrow() == optimizedChute.isNarrow();
        assert c3.hasBuzzsaw() == optimizedChute.hasBuzzsaw();
        assert !c1.hasBuzzsaw();
        assert !c2.hasBuzzsaw();
    }

    /**
     * Tests this case:
     *
     * <pre>
     * unoptimized
     *    X ---> Y ---> Z
     *       E1     E2
     * </pre>
     *
     * The optimized world & mapping is just the result of importing a
     * NodeGraph and exporting to a world again.
     *
     * Buzzsaws should be transferred successfully.
     *
     * @throws MismatchException
     */
    @Test
    public void testDefaultBuzzsawTransfer() throws MismatchException {

        Board board = new Board();
        Intersection in = board.addNode(Intersection.Kind.INCOMING);
        Intersection conn = board.addNode(Intersection.Kind.CONNECT);
        Intersection out = board.addNode(Intersection.Kind.OUTGOING);

        Chute c1 = new Chute(1, "");
        Chute c2 = new Chute(2, "");

        board.addEdge(in, "out", conn, "in1", c1);
        board.addEdge(conn, "out", out, "in2", c2);

        Level level = new Level();
        level.addBoard("board", board);
        World world = new World();
        world.addLevel("level", level);
        world.finishConstruction();

        //------------------------------

        ReverseMapping map = new ReverseMapping();
        World world2 = new NodeGraph(world).toWorld(map);

        //------------------------------

        List<Chute> edges = new ArrayList<>(world2.getChutes());
        assert edges.size() == 2;
        Chute c3 = edges.get(0).getVariableID() == 1 ? edges.get(0) : edges.get(1); // copy of c1
        Chute c4 = edges.get(0).getVariableID() == 1 ? edges.get(1) : edges.get(0); // copy of c2

        c3.setBuzzsaw(true);
        apply(map, world, world2);
        assert c1.hasBuzzsaw();
        assert !c2.hasBuzzsaw();

        c3.setBuzzsaw(false);
        apply(map, world, world2);
        assert !c1.hasBuzzsaw();
        assert !c2.hasBuzzsaw();

        c4.setBuzzsaw(true);
        apply(map, world, world2);
        assert !c1.hasBuzzsaw();
        assert c2.hasBuzzsaw();

        c4.setBuzzsaw(false);
        apply(map, world, world2);
        assert !c1.hasBuzzsaw();
        assert !c2.hasBuzzsaw();

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
        for (boolean narrow : Arrays.asList(true, false)) {
            Chute c1 = new Chute(1, "a");
            Chute c2 = new Chute(1, "b");
            c1.setEditable(true);
            c2.setEditable(true);
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
            Chute c3 = new Chute(1, "c");
            c3.setEditable(true);
            b2.add(Intersection.Kind.INCOMING, "1", Intersection.Kind.OUTGOING, "2", c3);
            Level l2 = new Level();
            l2.addBoard("b", b2);
            World optimized = new World();
            optimized.addLevel("l", l2);
            optimized.finishConstruction();

            c1.setNarrow(!narrow);
            c2.setNarrow(!narrow);
            c3.setNarrow(narrow);

            c3.setNarrow(false);
            apply(new ReverseMapping(), unoptimized, optimized);
            assert c1.isNarrow() == c3.isNarrow();
            assert c2.isNarrow() == c3.isNarrow();

            c3.setNarrow(true);
            apply(new ReverseMapping(), unoptimized, optimized);
            assert c1.isNarrow() == c3.isNarrow();
            assert c2.isNarrow() == c3.isNarrow();
        }
    }

}
