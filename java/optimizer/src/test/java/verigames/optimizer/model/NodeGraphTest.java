package verigames.optimizer.model;

import org.testng.annotations.Test;
import verigames.level.Board;
import verigames.level.Chute;
import verigames.level.Intersection;
import verigames.level.Level;
import verigames.level.RandomWorldGenerator;
import verigames.level.StubBoard;
import verigames.level.World;
import verigames.optimizer.Util;

import java.util.Arrays;
import java.util.Map;
import java.util.Random;

public class NodeGraphTest {

    @Test
    public void testEdgeSets() {
        NodeGraph g = new NodeGraph();
        Node one = new Node("a", null, "b", null, Intersection.factory(Intersection.Kind.INCOMING));
        Node two = Util.newNodeOnSameBoard(one, Intersection.Kind.OUTGOING);
        Node three = Util.newNodeOnSameBoard(two, Intersection.Kind.CONNECT);

        Chute c1 = new Chute(1, "c1");
        Chute c2 = new Chute(1, "c2");

        g.addEdge(one, Port.OUTPUT, two, Port.INPUT, c1);
        g.addEdge(two, Port.OUTPUT, three, Port.INPUT, c2);

        assert g.edgeSet(0).size() == 0;
        assert g.edgeSet(c1.getVariableID()).containsAll(g.getEdges());

        g.removeNode(three);
        assert g.edgeSet(1).size() == 1;
        assert g.edgeSet(c1.getVariableID()).containsAll(g.getEdges());

        g.addEdge(two, Port.OUTPUT, three, Port.INPUT, c2);
        g.addEdge(two, Port.OUTPUT, three, Port.INPUT, c2);
        assert g.edgeSet(c1.getVariableID()).size() == 2;

        assert g.edgeSet(c1.getVariableID()).containsAll(g.getEdges());
    }

    @Test
    public void testLinkedVarIDs() {
        NodeGraph g = new NodeGraph();
        Node one = new Node("a", null, "b", null, Intersection.factory(Intersection.Kind.INCOMING));
        Node two = Util.newNodeOnSameBoard(one, Intersection.Kind.OUTGOING);
        Node three = Util.newNodeOnSameBoard(two, Intersection.Kind.CONNECT);

        Chute c1 = new Chute(1, "c1");
        Chute c2 = new Chute(1, "c2");
        Chute c3 = new Chute(2, "c2");

        g.linkVarIDs(Arrays.asList(1, 2));

        g.addEdge(one, Port.OUTPUT, two, Port.INPUT, c1);
        g.addEdge(two, Port.OUTPUT, three, Port.INPUT, c2);
        g.addEdge(one, new Port("x"), two, new Port("y"), c3);

        assert g.edgeSet(1).containsAll(g.getEdges());
        assert g.edgeSet(2).containsAll(g.getEdges());
    }

    @Test
    public void testNegativeEdgeSets() {
        NodeGraph g = new NodeGraph();
        Node one = new Node("a", null, "b", null, Intersection.factory(Intersection.Kind.INCOMING));
        Node two = Util.newNodeOnSameBoard(one, Intersection.Kind.OUTGOING);
        Node three = Util.newNodeOnSameBoard(two, Intersection.Kind.CONNECT);

        Chute c1 = new Chute(1, "c1");
        Chute c2 = new Chute(-1, "c2");
        Chute c3 = new Chute(-1, "c3");

        g.addEdge(one, Port.OUTPUT, two, Port.INPUT, c1);
        g.addEdge(two, Port.OUTPUT, three, Port.INPUT, c2);
        g.addEdge(two, new Port("eh"), three, new Port("why"), c3);

        assert g.edgeSet(1).size() == 1;
        assert g.edgeSet(-1).size() == 0; // negative var ID means NO edge set
    }

    @Test
    public void testLoad() {
        World w = new RandomWorldGenerator(new Random(10)).randomWorld();
        NodeGraph g = new NodeGraph(w);

        // Check node presence
        for (Map.Entry<String, Level> levelEntry : w.getLevels().entrySet()) {
            String levelName = levelEntry.getKey();
            Level level = levelEntry.getValue();
            for (Board board : level.getBoards().values()) {
                String boardName = board.getName();
                for (Intersection i : board.getNodes()) {
                    Node n;
                    if (i.isSubboard()) {
                        Board b1 = w.getBoard(i.asSubboard().getSubnetworkName());
                        StubBoard b2 = w.getStubBoard(i.asSubboard().getSubnetworkName());
                        n = new Node(levelName, level, boardName, board, i, b1 == null ? new BoardRef(b2) : new BoardRef(b1));
                    } else {
                        n = new Node(levelName, level, boardName, board, i);
                    }
                    assert g.getNodes().contains(n);
                }
            }
        }

        // Check edge set presence
        for (NodeGraph.Edge e1 : g.getEdges()) {
            for (NodeGraph.Edge e2 : g.getEdges()) {
                if (w.areVarIDsLinked(e1.getEdgeData().getVariableID(), e2.getEdgeData().getVariableID())) {
                    assert g.edgeSet(e1).equals(g.edgeSet(e2));
                }
            }
        }

        // TODO: lots more stuff we could check here
    }

    @Test
    public void testDump() {
        // TODO: lots more stuff we could check here
        World w1 = new RandomWorldGenerator(new Random(10)).randomWorld();
        NodeGraph g1 = new NodeGraph(w1);
        World w2 = g1.toWorld();
        NodeGraph g2 = new NodeGraph(w2);
        assert g1.getNodes().size() == g2.getNodes().size();
        assert g1.getEdges().size() == g2.getEdges().size();
    }

}
