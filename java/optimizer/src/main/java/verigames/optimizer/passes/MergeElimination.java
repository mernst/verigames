package verigames.optimizer.passes;

import verigames.level.Board;
import verigames.level.Intersection;
import verigames.level.Level;
import verigames.optimizer.OptimizationPass;
import verigames.optimizer.Util;
import verigames.optimizer.model.Node;
import verigames.optimizer.model.NodeGraph;
import verigames.optimizer.model.Port;

import java.util.ArrayList;
import java.util.List;

/**
 * Eliminates merge nodes in the following form:
 *
 * <pre>
 * \  SMALL_DROP     |
 *  \ /              |
 *   Y      ----->   O
 *   |               |
 *   |               |
 * </pre>
 *
 * Where "Y" is a merge node and "O" is a connector.
 *
 * While not particularly common in real worlds, this is a <i>very</i> common
 * output from the {@link BallDropElimination} optimization pass. Note that
 * the connect nodes we generate are likely to be eliminated by the
 * {@link ConnectorCompression} pass.
 */
public class MergeElimination implements OptimizationPass {

    @Override
    public void optimize(NodeGraph g) {

        // wrap the nodes in a new array list to avoid concurrent modification
        // of a list we are iterating over
        for (Node n : new ArrayList<>(g.getNodes())) {

            if (n.getIntersection().getIntersectionKind() == Intersection.Kind.MERGE) {

                List<NodeGraph.Edge> incoming = new ArrayList<>(g.incomingEdges(n));
                NodeGraph.Edge e1 = incoming.get(0);
                NodeGraph.Edge e2 = incoming.get(1);
                NodeGraph.Target dst = Util.first(g.outgoingEdges(n).values());

                String levelName = n.getLevelName();
                Level level = n.getLevel();
                String boardName = n.getBoardName();
                Board board = n.getBoard();
                Intersection i = Intersection.factory(Intersection.Kind.CONNECT);
                Node connector = new Node(levelName, level, boardName, board, i);

                // If either node was a small ball drop, we need to remove this
                // merge and the drop and place a connector instead.
                if (e1.getSrc().getIntersection().getIntersectionKind() == Intersection.Kind.START_SMALL_BALL) {
                    g.removeNode(e1.getSrc());
                    g.removeNode(n);
                    g.addNode(connector);
                    g.addEdge(e2.getSrc(), e2.getSrcPort(), connector, Port.INPUT, e2.getEdgeData());
                    g.addEdge(connector, Port.OUTPUT, dst.getDst(), dst.getDstPort(), dst.getEdgeData());
                } else if (e2.getSrc().getIntersection().getIntersectionKind() == Intersection.Kind.START_SMALL_BALL) {
                    g.removeNode(e2.getSrc());
                    g.removeNode(n);
                    g.addNode(connector);
                    g.addEdge(e1.getSrc(), e1.getSrcPort(), connector, Port.INPUT, e1.getEdgeData());
                    g.addEdge(connector, Port.OUTPUT, dst.getDst(), dst.getDstPort(), dst.getEdgeData());
                }

            }

        }

    }

}
