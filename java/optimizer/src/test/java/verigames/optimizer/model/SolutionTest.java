package verigames.optimizer.model;

import org.testng.annotations.Test;
import verigames.level.Board;
import verigames.level.Chute;
import verigames.level.Intersection;
import verigames.level.Level;
import verigames.level.World;

@Test
public class SolutionTest {

    @Test
    public void testApply() {
        Board board = new Board();
        Intersection in = board.addNode(Intersection.Kind.INCOMING);
        Intersection conn = board.addNode(Intersection.Kind.CONNECT);
        Intersection out = board.addNode(Intersection.Kind.OUTGOING);

        Chute c1 = new Chute(1, "");
        Chute c2 = new Chute(2, "");
        Chute c3 = new Chute(2, "");

        board.addEdge(in, "out", conn, "in1", c1);
        board.addEdge(conn, "out", out, "in2", c2);
        board.addEdge(in, "out2", out, "in3", c3);

        Level level = new Level();
        level.addBoard("board", board);
        World world = new World();
        world.addLevel("level", level);
        world.finishConstruction();

        NodeGraph g = new NodeGraph(world);

        Edge e1 = null, e2 = null;
        for (Edge e : g.getEdges()) {
            if (e.getVariableID() == c1.getVariableID())
                e1 = e;
            else if (e.getVariableID() == c2.getVariableID())
                e2 = e;
        }

        Solution s = new Solution();
        s.setBuzzsaw(e1, true);
        s.setNarrow(e1, false);
        s.setNarrow(e2, true);

        s.applyTo(world);

        assert c1.hasBuzzsaw();
        assert !c2.hasBuzzsaw();
        assert !c1.isNarrow();
        assert c2.isNarrow();
        assert c3.isNarrow(); // same var ID as c2
    }

}
