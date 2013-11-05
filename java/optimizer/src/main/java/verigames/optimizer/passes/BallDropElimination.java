package verigames.optimizer.passes;

import verigames.level.Board;
import verigames.level.Chute;
import verigames.level.Intersection;
import verigames.level.Level;
import verigames.optimizer.OptimizationPass;
import verigames.optimizer.model.Node;
import verigames.optimizer.model.NodeGraph;
import verigames.optimizer.model.Port;

import java.util.Collection;
import java.util.Collections;
import java.util.HashSet;
import java.util.Set;

/**
 * Small ball drops (and no-ball drops) are often useless to the user, since they
 * don't create jams. This pass removes as many as possible.
 *
 * In addition, this pass converts empty ball drops into small ball drops. These are
 * effectively equivalent (they never create jams) and are more fun to look at. This
 * also means that subsequent optimizations have one less node type to worry about.
 */
public class BallDropElimination implements OptimizationPass {
    @Override
    public void optimize(NodeGraph g) {

        Set<Node> toRemove = Collections.emptySet();

        boolean shouldContinue;

        do {
            Set<Node> toRemove2 = new HashSet<>();

            for (Node n : g.getNodes()) {
                if (toRemove.contains(n)) {
                    toRemove2.add(n);
                    continue;
                }
                Intersection i = n.getIntersection();
                Intersection.Kind kind = i.getIntersectionKind();
                if (kind == Intersection.Kind.START_SMALL_BALL || kind == Intersection.Kind.START_NO_BALL) {
                    toRemove2.add(n);
                    break;
                }
                Collection<NodeGraph.Edge> incoming = g.incomingEdges(n);
                if (incoming.size() > 0 && kind != Intersection.Kind.OUTGOING) {
                    boolean allSourcesBeingRemoved = true;
                    for (NodeGraph.Edge e : incoming) {
                        if (!toRemove.contains(e.getSrc())) {
                            allSourcesBeingRemoved = false;
                            break;
                        }
                    }
                    if (allSourcesBeingRemoved) {
                        toRemove2.add(n);
                    }
                }
            }

            shouldContinue = !toRemove.equals(toRemove2);
            toRemove = toRemove2;
        } while (shouldContinue);

        // We might have overzealously removed nodes, e.g. if only one
        // input to a subboard got removed. In this case, we need to
        // patch it up by adding some appropriate small ball drops.
        Set<NodeGraph.Target> dangling = new HashSet<>();
        for (Node n : toRemove) {
            for (NodeGraph.Target t : g.outgoingEdges(n).values()) {
                if (!toRemove.contains(t.getDst())) {
                    dangling.add(t);
                }
            }
        }

        g.removeNodes(toRemove);
        for (NodeGraph.Target t : dangling) {
            String levelName = t.getDst().getLevelName();
            Level level = t.getDst().getLevel();
            String boardName = t.getDst().getBoardName();
            Board board = t.getDst().getBoard();
            Intersection intersection = Intersection.factory(Intersection.Kind.START_SMALL_BALL);
            Chute chute = new Chute();
            chute.setNarrow(true);
            chute.setEditable(false);
            Node n = new Node(levelName, level, boardName, board, intersection);
            g.addNode(n);
            g.addEdge(n, Port.OUTPUT, t.getDst(), t.getDstPort(), chute);
        }
    }
}
