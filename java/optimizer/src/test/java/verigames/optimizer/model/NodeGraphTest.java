package verigames.optimizer.model;

import org.testng.annotations.Test;
import verigames.level.Chute;
import verigames.level.Intersection;
import verigames.optimizer.Util;

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
        assert g.edgeSet(c1.getVariableID()).size() == 2;
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

}
