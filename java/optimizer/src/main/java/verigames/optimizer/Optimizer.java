package verigames.optimizer;

import verigames.level.Board;
import verigames.level.Chute;
import verigames.level.Intersection;
import verigames.level.Level;
import verigames.level.World;
import verigames.optimizer.model.Node;
import verigames.optimizer.model.NodeGraph;
import verigames.optimizer.model.Port;
import verigames.optimizer.model.Subgraph;

import java.util.ArrayList;
import java.util.Collection;
import java.util.Collections;
import java.util.HashSet;
import java.util.Set;

public class Optimizer {

    public void optimize(NodeGraph g) {
        removeSmallBallDrops(g);
        removeIsolatedComponents(g);
        compressConnectors(g);
    }

    /**
     * Small ball drops are often useless to the user, since they
     * don't create jams. This pass removes as many as possible.
     * @param g the graph to modify
     */
    public void removeSmallBallDrops(NodeGraph g) {

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

    /**
     * Remove isolated, immutable components from the graph. If
     * every chute in a component is immutable, then the user
     * probably doesn't care about it.
     * @param g the graph to modify
     */
    public void removeIsolatedComponents(NodeGraph g) {
        for (Subgraph subgraph : g.getComponents()) {
            boolean mutable = false;
            for (NodeGraph.Edge edge : subgraph.getEdges()) {
                mutable = edge.getEdgeData().isEditable();
                if (mutable)
                    break;
            }
            boolean hasFixedNode = false;
            for (Node node : subgraph.getNodes()) {
                Intersection.Kind kind = node.getIntersection().getIntersectionKind();
                hasFixedNode = (kind == Intersection.Kind.INCOMING || kind == Intersection.Kind.OUTGOING);
                if (hasFixedNode)
                    break;
            }
            if (!mutable && !hasFixedNode) {
                Util.logVerbose("*** REMOVING IMMUTABLE SUBGRAPH (" + subgraph.getNodes().size() + " nodes, " + subgraph.getEdges().size() + " edges)");
                g.removeSubgraph(subgraph);
            }
        }
    }

    /**
     * Remove useless one-input to one-output connectors in the
     * graph.
     * @param g the graph to modify
     */
    public void compressConnectors(NodeGraph g) {
        // remove a lot of "connect" intersections
        // Note: the new ArrayList is because we remove nodes from the graph as we go,
        // and getNodes just returns a view of the nodes in the graph. We want to
        // avoid concurrent modifications.
        for (Node node : new ArrayList<>(g.getNodes())) {
            if (node.getIntersection().getIntersectionKind() == Intersection.Kind.CONNECT) {
                // for this node kind: one incoming edge, one outgoing edge
                NodeGraph.Edge incomingEdge = Util.first(g.incomingEdges(node));
                NodeGraph.Target outgoingEdge = Util.first(g.outgoingEdges(node).values());

                Chute incomingChute = incomingEdge.getEdgeData();
                Chute outgoingChute = outgoingEdge.getEdgeData();

                // if either edge belongs to an edge set, we can't merge them
                Collection<NodeGraph.Edge> iEdgeSet = g.edgeSet(incomingEdge);
                Collection<NodeGraph.Edge> oEdgeSet = g.edgeSet(outgoingEdge);
                if ((iEdgeSet.size() > 1 || oEdgeSet.size() > 1) &&
                        // however, if both edges are part of the same set, we can merge them!
                        !(incomingChute.getVariableID() == outgoingChute.getVariableID())) {
                    continue;
                }

                // if the edges are different widths, we have to think really hard about how to merge them
                boolean narrow = incomingChute.isNarrow();
                if (incomingChute.isNarrow() != outgoingChute.isNarrow()) {
                    if (incomingChute.isEditable())          // if we can edit the incoming chute...
                        narrow = outgoingChute.isNarrow();   //     ... then make it match the outgoing one
                    else if (outgoingChute.isEditable())     // if we can edit the outgoing chute...
                        narrow = incomingChute.isNarrow();   //     ... then make it match the incoming one
                    else if (incomingChute.isNarrow() && !outgoingChute.isNarrow()) // if the edges are immutable and narrow flows to wide
                        narrow = true;                       //     ... then make it narrow
                    else                                     // if the edges are immutable and wide flows to narrow
                        continue;                            //     ... then we're out of luck
                }

                Util.logVerbose("*** REMOVING USELESS CONNECTOR");

                // remove the node
                g.removeNode(node);

                // add an edge where it used to be
                Chute newChute = new Chute(outgoingChute.getVariableID(), outgoingChute.getDescription());
                newChute.setBuzzsaw(incomingChute.hasBuzzsaw() || outgoingChute.hasBuzzsaw());
                if (outgoingChute.getLayout() != null)
                    newChute.setLayout(outgoingChute.getLayout());
                newChute.setNarrow(narrow);
                newChute.setEditable(incomingChute.isEditable() && outgoingChute.isEditable());
                newChute.setPinched(incomingChute.isPinched() || outgoingChute.isPinched());
                g.addEdge(
                        incomingEdge.getSrc(), incomingEdge.getSrcPort(),
                        outgoingEdge.getDst(), outgoingEdge.getDstPort(),
                        newChute);
            }
        }
    }

    public World optimizeWorld(World source) {
        NodeGraph g = new NodeGraph(source);
        System.err.println("Starting optimization: " + g.getNodes().size() + " nodes, " + g.getEdges().size() + " edges");
        optimize(g);
        System.err.println("Finished optimization: " + g.getNodes().size() + " nodes, " + g.getEdges().size() + " edges");
        return g.toWorld();
    }

}
