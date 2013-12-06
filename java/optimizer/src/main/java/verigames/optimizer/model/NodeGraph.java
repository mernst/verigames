package verigames.optimizer.model;

import verigames.level.Board;
import verigames.level.Chute;
import verigames.level.Intersection;
import verigames.level.Level;
import verigames.level.StubBoard;
import verigames.level.World;
import verigames.optimizer.common.DisjointSet;
import verigames.utilities.MultiMap;

import java.util.AbstractCollection;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Collections;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Iterator;
import java.util.Map;
import java.util.Set;

/**
 * A mutable graph representing a {@link verigames.level.World}.
 */
public class NodeGraph {

    // READER BEWARE
    // The NodeGraph class does an immense amount of internal bookkeeping to
    // make most operations very very fast. That results in a lot of
    // complexity in this file.

    protected static class Target {
        private final Node dst;
        private final Port dstPort;
        private final EdgeData edgeData;
        public Target(Node dst, Port dstPort, EdgeData edgeData) {
            this.dst = dst;
            this.dstPort = dstPort;
            this.edgeData = edgeData;
        }

        public Node getDst() {
            return dst;
        }

        public Port getDstPort() {
            return dstPort;
        }

        public EdgeData getEdgeData() {
            return edgeData;
        }

        @Override
        public boolean equals(Object o) {
            if (this == o) return true;
            if (o == null || getClass() != o.getClass()) return false;

            Target target = (Target) o;

            if (!dst.equals(target.dst)) return false;
            if (!dstPort.equals(target.dstPort)) return false;
            if (!edgeData.equals(target.edgeData)) return false;

            return true;
        }

        @Override
        public int hashCode() {
            int result = dst.hashCode();
            result = 31 * result + dstPort.hashCode();
            result = 31 * result + edgeData.hashCode();
            return result;
        }
    }

    /**
     * Conceptually, an edge connects a port on one node to a
     * port on another. This map is a strange way of storing
     * that info, but gives us a lot of efficiency. It maps
     * every source Node to a set of Port mappings. A Port
     * mapping maps a source Port to a collection of (Node, Port)
     * destination pairs.
     *
     * <p>Here, however, we store an additional piece of data:
     * the {@link EdgeData} for the edge. To keep things simple,
     * the (Node, Port, EdgeData) info is extracted into the
     * {@link Target} class which encapsulates all this data.
     *
     * <p>NOTE: A key is present if and only if the node is in the
     * graph. This is used to store the set of nodes.
     */
    private final Map<Node, Map<Port, Target>> edges;

    /**
     * Very often we want to look up what flows INTO a node, not
     * just OUT of it. This reverse lookup table makes it much
     * easier to answer that question by linking each node X to
     * the set of nodes that have at least one edge flowing into X.
     *
     * <p>Note that this representation is based on the observation
     * that, for our use case, the degree of a node is very, very
     * small (typically not more than 3, very very rarely more than
     * 10).
     */
    private final MultiMap<Node, Node> redges;

    /**
     * Maps variable IDs (integers) to edge sets. Note that this is
     * not a simple MultiMap: multiple variable IDs might point to
     * the same edge set if those variable IDs are linked.
     */
    private final Map<Integer, Set<Edge>> edgeSets;

    public NodeGraph() {
        edges = new HashMap<>();
        redges = new MultiMap<>();
        edgeSets = new HashMap<>();
    }

    public NodeGraph(World w) {
        this();

        // set up edge sets
        Set<Set<Integer>> linkedVars = w.getLinkedVarIDs();
        for (Set<Integer> varIDs : linkedVars) {
            linkVarIDs(varIDs);
        }

        // go through each board and extract all the intersections & chutes
        Map<Intersection, Node> nodeMap = new HashMap<>();
        for (Map.Entry<String, Level> levelEntry : w.getLevels().entrySet()) {
            final String levelName = levelEntry.getKey();
            final Level level = levelEntry.getValue();
            for (Map.Entry<String, Board> boardEntry : level.getBoards().entrySet()) {
                final String boardName = boardEntry.getKey();
                final Board board = boardEntry.getValue();
                for (Intersection intersection : board.getNodes()) {
                    final Node node;
                    if (intersection.isSubboard()) {
                        String subboardName = intersection.asSubboard().getSubnetworkName();
                        Board subBoard = w.getBoard(subboardName);
                        StubBoard stubBoard = w.getStubBoard(subboardName);
                        assert (subBoard != null) ^ (stubBoard != null);
                        BoardRef ref = subBoard != null ? new BoardRef(subBoard) : new BoardRef(stubBoard);
                        node = new Node(levelName, boardName, intersection, ref);
                    } else {
                        node = new Node(levelName, boardName, intersection);
                    }
                    nodeMap.put(intersection, node);
                    addNode(node);
                }
                for (Chute chute : board.getEdges()) {
                    addEdge(nodeMap.get(chute.getStart()), new Port(chute.getStartPort()),
                            nodeMap.get(chute.getEnd()), new Port(chute.getEndPort()),
                            EdgeData.fromChute(chute));
                }
            }
        }

    }

    /**
     * Create a new world from this graph.
     * @return a fully constructed world
     */
    public World toWorld() {
        return toWorld(new ReverseMapping());
    }

    /**
     * Construct an intersection whose UID is NOT in the set of reserved IDs.
     *
     * <p>Why do we need this, you might ask? And that is a reasonable question.
     * Sadly we decided to use ints for IDs instead of something more sane, like
     * {@link java.util.UUID}. As a result, the world export routine may
     * accidentally construct intersections with IDs that already existed in the
     * imported world. This routine helps us avoid that.
     * @param reserved        forbidden IDs
     * @param kind            intersection kind
     * @param subnetworkName  subnetwork name (ignored when kind != SUBBOARD)
     * @return a new intersection
     */
    private Intersection intersectionWithFreshID(Set<Integer> reserved, Intersection.Kind kind, String subnetworkName) {
        Intersection i;
        do {
            i = (kind == Intersection.Kind.SUBBOARD) ?
                    Intersection.subboardFactory(subnetworkName) :
                    Intersection.factory(kind);
        } while (reserved.contains(i.getUID()));
        return i;
    }

    /**
     * Create a new world from this graph.
     * @param mapping a reverse mapping to update (since some things may get renamed during export)
     * @return a fully constructed world
     */
    public World toWorld(ReverseMapping mapping) {
        World world = new World();

        // Assemble some info
        Collection<Edge> edges = getEdges();
        MultiMap<String, Node> nodesByLevel = new MultiMap<>();
        MultiMap<String, Node> nodesByBoard = new MultiMap<>();
        MultiMap<String, String> boardsByLevel = new MultiMap<>();
        MultiMap<String, Edge> edgesByBoard = new MultiMap<>();
        Map<Node, Intersection> newIntersectionsByNode = new HashMap<>();
        Set<Integer> reservedIDs = new HashSet<>();
        for (Node n : getNodes()) {
            reservedIDs.add(n.getIntersection().getUID());
        }
        for (Node n : getNodes()) {
            nodesByLevel.put(n.getLevelName(), n);
            nodesByBoard.put(n.getBoardName(), n);
            boardsByLevel.put(n.getLevelName(), n.getBoardName());

            Intersection intersection = n.getIntersection();
            int id = intersection.getUID();
            Intersection newIntersection;
            if (intersection.getIntersectionKind() == Intersection.Kind.SUBBOARD) {
                String subnetworkName = intersection.asSubboard().getSubnetworkName();
                newIntersection = intersectionWithFreshID(reservedIDs, Intersection.Kind.SUBBOARD, subnetworkName);
            } else {
                newIntersection = intersectionWithFreshID(reservedIDs, intersection.getIntersectionKind(), null);
            }
            if (intersection.getX() >= 0)
                newIntersection.setX(intersection.getX());
            if (intersection.getY() >= 0)
                newIntersection.setY(intersection.getY());
            newIntersectionsByNode.put(n, newIntersection);
        }
        for (Edge e : edges) {
            edgesByBoard.put(e.getSrc().getBoardName(), e);
        }

        // Build the data structure
        for (String levelName : nodesByLevel.keySet()) {
            Level newLevel = new Level();
            for (String boardName : boardsByLevel.get(levelName)) {
                Set<Node> boardNodes = nodesByBoard.get(boardName);
                Board newBoard = new Board(boardName);

                // Inane restriction on Boards: callers must add incoming node first
                Node incoming = null;
                for (Node node : boardNodes) {
                    if (node.getIntersection().getIntersectionKind() == Intersection.Kind.INCOMING) {
                        incoming = node;
                        break;
                    }
                }
                if (incoming == null)
                    throw new RuntimeException("No incoming node exists for board '" + boardName + "'");
                newBoard.addNode(newIntersectionsByNode.get(incoming));

                // add the rest
                for (Node node : boardNodes) {
                    if (node != incoming) // do not add the incoming node twice
                        newBoard.addNode(newIntersectionsByNode.get(node));
                    if (node.getIntersection().isSubboard()) {
                        String subboardName = node.getIntersection().asSubboard().getSubnetworkName();
                        BoardRef ref = node.getBoardRef();
                        if (ref.isStub() && world.getStubBoard(subboardName) == null && !newLevel.contains(subboardName)) {
                            newLevel.addStubBoard(subboardName, ref.asStubBoard());
                        }
                    }
                }
                for (Edge edge : edgesByBoard.get(boardName)) {
                    Chute newChute = edge.getEdgeData().toChute();
                    Intersection start = newIntersectionsByNode.get(edge.getSrc());
                    String startPort = edge.getSrcPort().getName();
                    Intersection end = newIntersectionsByNode.get(edge.getDst());
                    String endPort = edge.getDstPort().getName();
                    newBoard.add(start, startPort, end, endPort, newChute);
                    EdgeID oldid = new EdgeID(edge);
                    EdgeID newid = new EdgeID(newChute);
                    if (edge.isEditable() && !mapping.hasWidthMapping(edge))
                        mapping.mapEdge(oldid, newid);
                    if (!mapping.hasBuzzsawMapping(edge))
                        mapping.mapBuzzsaw(oldid, newid);
                }
                newLevel.addBoard(boardName, newBoard);
            }
            world.addLevel(levelName, newLevel);
        }

        // Link up var IDs
        Set<Integer> varIDsToSave = new HashSet<>();
        for (Edge e : edges) {
            varIDsToSave.add(e.getVariableID());
        }
        Map<Integer, Integer> canonicalVars = new HashMap<>();
        for (Map.Entry<Integer, Set<Edge>> entry : edgeSets.entrySet()) {
            Integer varID = entry.getKey();
            if (varIDsToSave.contains(varID)) {
                Set<Edge> edgeSet = entry.getValue();
                for (Edge e : edgeSet) {
                    canonicalVars.put(e.getVariableID(), varID);
                }
            }
        }
        for (Map.Entry<Integer, Set<Edge>> entry : edgeSets.entrySet()) {
            Integer varID = entry.getKey();
            if (varIDsToSave.contains(varID)) {
                Integer canonical = canonicalVars.get(varID);
                if (canonical != null && !canonical.equals(varID)) {
                    for (Edge e : entry.getValue()) {
                        if (e.getEdgeData().getVariableID() == varID) {
                            world.linkByVarID(varID, canonical);
                            break;
                        }
                    }
                }
            }
        }

        world.finishConstruction();
        return world;
    }

    public void addNode(Node n) {
        if (!edges.containsKey(n)) {
            edges.put(n, new HashMap<Port, Target>());
        }
    }

    public void removeNode(Node n) {
        // Step 1: remove the edges out of this node
        Collection<Edge> toRemove = new ArrayList<>();
        Map<Port, Target> outgoing = edges.get(n);
        if (outgoing != null) {
            for (Map.Entry<Port, Target> entry : outgoing.entrySet()) {
                Target target = entry.getValue();
                toRemove.add(new Edge(n, entry.getKey(), target));
            }
        }

        // Step 2: remove edges into this node
        for (Node src : redges.get(n)) {
            outgoing = edges.get(src);
            if (outgoing != null) { // shouldn't happen, but let's be careful...
                for (Map.Entry<Port, Target> entry : outgoing.entrySet()) {
                    Target target = entry.getValue();
                    if (target.getDst().equals(n))
                        toRemove.add(new Edge(src, entry.getKey(), target));
                }
            }
        }

        for (Edge e : toRemove) {
            removeEdge(e);
        }

        // Step 3: cleanup
        redges.remove(n);
        edges.remove(n);
    }

    public void removeNodes(Collection<Node> toRemove) {
        for (Node node : toRemove) {
            removeNode(node);
        }
    }

    public Collection<Node> getNodes() {
        return edges.keySet();
    }

    /**
     * Add an edge (if it wasn't already present). This will also add the given nodes,
     * if they are not already present.
     */
    public Edge addEdge(Node src, Port srcPort, Node dst, Port dstPort, EdgeData edgeData) {
        addNode(src);
        addNode(dst);
        Target target = new Target(dst, dstPort, edgeData);
        edges.get(src).put(srcPort, target);
        redges.put(dst, src);
        Edge e = new Edge(src, srcPort, target);
        if (edgeData.getVariableID() >= 0) {
            Set<Edge> edgeSet = edgeSets.get(edgeData.getVariableID());
            if (edgeSet == null) {
                edgeSet = new HashSet<>();
                edgeSets.put(edgeData.getVariableID(), edgeSet);
            }
            edgeSet.add(e);
        }
        return e;
    }

    /**
     * Remove an edge (if present). The getNodes of the edge are not removed, even if they
     * are disconnected from the graph as a result of this action.
     */
    public void removeEdge(Node src, Port srcPort, Node dst, Port dstPort) {
        Map<Port, Target> dsts = edges.get(src);
        if (dsts == null)
            return;

        Target target = dsts.get(srcPort);
        if (target != null && target.dst.equals(dst) && target.dstPort.equals(dstPort)) {
            dsts.remove(srcPort);
            Set<Edge> edgeSet = edgeSets.get(target.getEdgeData().getVariableID());
            if (edgeSet != null) {
                edgeSet.remove(new Edge(src, srcPort, target));
                // NOTE: we do NOT remove empty edge sets because their presence still
                // conveys some meaningful info. I.e. even if we remove all edges with
                // a given var ID, that var ID should remain linked to the same set.
            }
        }

        boolean removeReverseEdge = true;
        for (Map.Entry<Port, Target> entry : dsts.entrySet()) {
            if (entry.getValue().getDst().equals(dst)) {
                removeReverseEdge = false;
                break;
            }
        }
        if (removeReverseEdge) {
            redges.remove(dst, src);
        }
    }

    public void removeEdge(Edge e) {
        removeEdge(e.getSrc(), e.getSrcPort(), e.getDst(), e.getDstPort());
    }

    public void removeEdges(Collection<Edge> toRemove) {
        for (Edge e : toRemove) {
            removeEdge(e);
        }
    }

    public Collection<Edge> getEdges() {
        // TODO: return a view, not a copy
        Collection<Edge> edgesList = new ArrayList<Edge>();
        for (Map.Entry<Node, Map<Port, Target>> entry : edges.entrySet()) {
            for (Map.Entry<Port, Target> entry2 : entry.getValue().entrySet()) {
                edgesList.add(new Edge(entry.getKey(), entry2.getKey(), entry2.getValue()));
            }
        }
        return edgesList;
    }

    public Collection<Set<Edge>> getEdgeSets() {
        // edgeSets.values may contain duplicates
        return new HashSet<>(edgeSets.values());
    }

    public Set<Edge> edgeSet(Edge edge) {
        return edgeSet(edge.getTarget());
    }

    public Set<Edge> edgeSet(Target edge) {
        return edgeSet(edge.getEdgeData().getVariableID());
    }

    public Set<Edge> edgeSet(Integer variableID) {
        Set<Edge> result = edgeSets.get(variableID);
        return result == null ? Collections.<Edge>emptySet() : result;
    }

    /**
     * Determine whether two edges are linked (should always share the same
     * width). The edges do NOT need to be in this graph, only their var IDs
     * are considered.
     * @param e1 the first edge
     * @param e2 the second edge
     * @return true if e1 and e2 are linked
     */
    public boolean areLinked(Edge e1, Edge e2) {
        return e1.getVariableID() >= 0 &&
                e2.getVariableID() >= 0 &&
                edgeSet(e1).contains(e2);
    }

    /**
     * Determine whether two var IDs are linked.
     * @param varID1 the first var id
     * @param varID2 the second var id
     * @return true if varID1 and varID2 are linked
     */
    public boolean areLinked(int varID1, int varID2) {
        return varID1 >= 0 &&
                varID2 >= 0 &&
                edgeSets.get(varID1) != null &&
                edgeSets.get(varID1) == edgeSets.get(varID2);
    }

    /**
     * Indicate that all the variables in the given collection should
     * be linked. See {@link World#linkByVarID(int, int)} for more info.
     * @param varIDs a collection of var IDs to link
     */
    public void linkVarIDs(Collection<Integer> varIDs) {
        Iterator<Integer> i = varIDs.iterator();
        if (!i.hasNext())
            return;
        Integer v1 = i.next();
        Set<Edge> set1 = edgeSets.get(v1);
        if (set1 == null) {
            set1 = new HashSet<>();
            edgeSets.put(v1, set1);
        }
        while (i.hasNext()) {
            Integer v2 = i.next();
            Set<Edge> set2 = edgeSets.get(v2);
            if (set2 != null) {
                set1.addAll(set2);
            }
            edgeSets.put(v2, set1);
        }
    }

    /**
     * Get the outgoing edges from a node
     * @param src the node
     * @return    the outgoing edges from the given node
     */
    public Collection<Edge> outgoingEdges(final Node src) {
        Map<Port, Target> map = edges.get(src);
        final Map<Port, Target> result = map == null ? Collections.<Port, Target>emptyMap() : map;
        return new AbstractCollection<Edge>() {
            @Override
            public Iterator<Edge> iterator() {
                final Iterator<Map.Entry<Port, Target>> i = result.entrySet().iterator();
                return new Iterator<Edge>() {
                    @Override
                    public boolean hasNext() {
                        return i.hasNext();
                    }
                    @Override
                    public Edge next() {
                        Map.Entry<Port, Target> entry = i.next();
                        return new Edge(src, entry.getKey(), entry.getValue());
                    }
                    @Override
                    public void remove() {
                        i.remove();
                    }
                };
            }
            @Override
            public int size() {
                return result.size();
            }
        };
    }

    /**
     * Get the incoming edges to a node
     * @param dst the node
     * @return    the incoming edges to the given node
     */
    public Collection<Edge> incomingEdges(Node dst) {
        Collection<Node> srcs = redges.get(dst);
        Collection<Edge> result = new ArrayList<>();
        for (Node src : srcs) {
            for (Map.Entry<Port, Target> entry : edges.get(src).entrySet()) {
                if (entry.getValue().getDst().equals(dst)) {
                    result.add(new Edge(src, entry.getKey(), entry.getValue()));
                }
            }
        }
        return result;
    }

    public Collection<Subgraph> getComponents() {

        // Step 1: collect connected nodes into distinct sets
        Map<Node, DisjointSet> components = new HashMap<>();
        for (Node n : getNodes()) {
            components.put(n, new DisjointSet());
        }
        Collection<Edge> edges = getEdges();
        for (Edge edge : edges) {
            components.get(edge.getSrc()).unionWith(components.get(edge.getTarget().getDst()));
        }

        // Step 2: create subgraphs with nodes
        Map<DisjointSet, Subgraph> subgraphs = new HashMap<>();
        for (Map.Entry<Node, DisjointSet> entry : components.entrySet()) {
            DisjointSet set = entry.getValue();
            Subgraph subgraph = subgraphs.get(set);
            if (subgraph == null) {
                subgraph = new Subgraph();
                subgraphs.put(set, subgraph);
            }
            subgraph.addNode(entry.getKey());
        }

        // Step 3: add edges to each subgraph
        for (Edge edge : edges) {
            Subgraph subgraph = subgraphs.get(components.get(edge.getSrc()));
            subgraph.addEdge(edge);
        }

        return new ArrayList<>(subgraphs.values());
    }

    public void removeSubgraph(Subgraph subgraph) {
        for (Edge e : subgraph.getEdges()) {
            removeEdge(e);
        }
        for (Node n : subgraph.getNodes()) {
            removeNode(n);
        }
    }

}
