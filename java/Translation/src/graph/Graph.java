package graph;

import java.util.LinkedHashSet;
import java.util.Set;

/**
 * A mutable graph structure capable of storing data in both the edges and the
 * nodes. It keeps track of the specific node ports to which edges attach.<br/>
 * <br/>
 * Once {@code deactivate()} is called, its structure becomes immutable, though
 * nodes and edges may still mutate in such a way that they do not change the
 * structure of the {@code Graph}<br/>
 * <br/>
 * Specification Field: {@code nodes} : {@code Set<NodeType>}
 * // the set of nodes contained in {@code this}<br/>
 * Specification Field: {@code edges} : {@code Set<EdgeType>}
 * // the set of edges contained in {@code this}<br/>
 * <br/>
 * Specification Field: {@code active} : {@code boolean} // {@code true} iff
 * {@code this} can still be modified. Once {@code active} is set to
 * {@code false}, {@code this} becomes immutable.
 * 
 * @param <NodeType>
 * The type of the nodes in {@code this}. Its edge type must be {@code EdgeType}
 * @param <EdgeType>
 * The type of the edges in {@code this}. Its node type must be {@code NodeType}
 * 
 * @author Nathaniel Mote
 */

public class Graph<NodeType extends Node<EdgeType>, EdgeType extends Edge<NodeType>>
{
   
   private static final boolean CHECK_REP_ENABLED = true;
   private Set<NodeType> nodes;
   private Set<EdgeType> edges;
   private boolean active = true;

   /**
    * Constructs a new, active {@code Graph} with no nodes or edges.
    */
   public Graph()
   {
      nodes = new LinkedHashSet<NodeType>();
      edges = new LinkedHashSet<EdgeType>();
   }

   /**
    * Ensures that the representation invariant holds.
    */
   protected void checkRep()
   {
      if (CHECK_REP_ENABLED)
      {
         // Representation Invariant:
         
         // nodes != null:
         ensure(nodes != null);
         // edges != null
         ensure(edges != null);
         
         
         // for all n in nodes; e in edges:
         // e.getStart() == n <--> n.getOutput(e.getStartPort()) == e
         // e.getEnd() == n <--> n.getInput(e.getEndPort()) == e
         for (EdgeType e : edges)
         {
            NodeType n = e.getStart();
            // e.getStart() == n --> n.getOutput(e.getStartPort()) == e
            ensure(n.getOutput(e.getStartPort()) == e);
            
            n = e.getEnd();
            // e.getEnd() == n --> n.getInput(e.getEndPort()) == e
            ensure(n.getInput(e.getEndPort()) == e);
         }
         
         for (NodeType n : nodes)
         {
            
            // This approach stops verifying after encountering the first port
            // with a null value. Therefore, it may not always check every
            // existing output port
            
            EdgeType e = n.getOutput(0);
            for (int i = 0; e != null; e = n.getOutput(++i))
            {
               // e.getStart() == n <-- n.getOutput(e.getStartPort()) == e
               ensure(i == e.getStartPort());
               ensure(e.getStart() == n);
            }
            
            e = n.getInput(0);
            for (int i = 0; e != null; e = n.getInput(++i))
            {
               // e.getEnd() == n <-- n.getInput(e.getEndPort()) == e
               ensure(i == e.getEndPort());
               ensure(e.getEnd() == n);
            }
         }
      }
   }

   /**
    * Intended to be a substitute for assert, except I don't want to have to
    * make sure the -ea flag is turned on in order to get these checks.
    */
   private void ensure(boolean value)
   {
      if (!value)
         throw new AssertionError();
   }

   /**
    * Adds {@code node} to {@code this}.<br/>
    * <br/>
    * Requires:<br/>
    * - {@link #isActive()}<br/>
    * - {@code node} can be added to {@code this}. This implementation allows
    * any node to be added, but subclasses are free to enforce arbitrary
    * restrictions on nodes to be added.<br/>
    * <br/>
    * Modifies: {@code this}
    * 
    * @param node
    * The node to add. Must be active, must not be contained in {@code this},
    * and must implement eternal equality.
    */
   public void addNode(NodeType node)
   {
      if (!active)
         throw new IllegalStateException("Mutation attempted on an inactive Board");
      if (!node.isActive())
         throw new IllegalStateException("Inactive node added to Board");
      
      if (this.contains(node))
         throw new IllegalArgumentException(
               "this already contains given node");
      
      nodes.add(node);
      checkRep();
   }

   /**
    * Adds an edge from {@code startPort} on {@code start} to {@code endPort} on
    * {@code end}.<br/>
    * <br/>
    * Modifies: {@code start}, {@code end}, and {@code edge} to reflect their
    * new connections.<br/>
    * <br/>
    * Requires:<br/>
    * - {@link #isActive()}<br/>
    * 
    * @param start
    * The node at which the edge will start. Must be active, and must be
    * contained in {@code this}.
    * @param startPort
    * The port at which the added edge will start. The output port of this
    * number on {@code start} must be empty.
    * @param end
    * The node at which the edge will end. Must be active, and must be contained
    * in {@code this}.
    * @param endPort
    * The port at which the added edge will end. The input port of this number
    * on {@code end} must be empty.
    * @param edge
    * The edge to add. Must be active, have no start or end nodes, and must not
    * be contained in {@code this}. This implementation enforces no further
    * restrictions on what edges can be added or what nodes they can be
    * connected to, but subclasses may.
    */
   public void addEdge(NodeType start, int startPort, NodeType end, int endPort,
         EdgeType edge)
   {
      if (!active)
         throw new IllegalStateException("Mutation attempted on an inactive Graph");
      if (!edge.isActive())
         throw new IllegalArgumentException("Graph.addEdge called with an inactive edge");
      
      if (!this.contains(start))
         throw new IllegalArgumentException(
               "Call to addEdge made with a start node that is not in this Graph");
      if (!this.contains(end))
         throw new IllegalArgumentException(
               "Call to addEdge made with a end node that is not in this Graph");
      if (this.contains(edge))
         throw new IllegalArgumentException(
               "Call to addEdge made with an edge that is already in this Graph");
      if (edge.getStart() != null || edge.getEnd() != null)
         throw new IllegalArgumentException(
               "Call to addEdge made with an edge that is already connected to node(s)");
      if (start.getOutput(startPort) != null)
         throw new IllegalArgumentException(
               "Call to addEdge made with a start node that is already connected to an edge on the given port");
      if (end.getInput(endPort) != null)
         throw new IllegalArgumentException(
               "Call to addEdge made with an end node that is already connected to an edge on the given port");
      
      edges.add(edge);
      
      start.setOutput(edge, startPort);
      end.setInput(edge, endPort);
      
      edge.setStart(start, startPort);
      edge.setEnd(end, endPort);
      
      checkRep();
   }

   /**
    * Returns the cardinality of {@code nodes}.<br/>
    * <br/>
    * May be more efficient than {@code getNodes().size()}
    */
   public int nodesSize()
   {
      return nodes.size();
   }

   /**
    * Returns the cardinality of {@code edges}<br/>
    * <br/>
    * May be more efficient than {@code getEdges().size()}
    */
   public int edgesSize()
   {
      return edges.size();
   }

   /**
    * Returns a {@code Set<NodeType>} with all nodes in {@code this}. The
    * returned set will not be affected by future changes to {@code this}, and
    * changes to the returned set will not affect {@code this}.
    */
   public Set<NodeType> getNodes()
   {
      return new LinkedHashSet<NodeType>(nodes);
   }

   /**
    * Returns a {@code Set<EdgeType>} with all edge objects in {@code this}. The returned set
    * will not be affected by future changes to {@code this}, and changes to the
    * returned set will not affect {@code this}.
    */
   public Set<EdgeType> getEdges()
   {
      return new LinkedHashSet<EdgeType>(edges);
   }

   /**
    * Returns {@code true} iff {@code nodes} contains {@code elt} or
    * {@code edges} contains {@code elt}<br/>
    * <br/>
    * May be more efficient than
    * {@code getNodes().contains(elt) || getEdges.contains(elt)}
    */
   public boolean contains(Object elt)
   {
      return nodes.contains(elt) || edges.contains(elt);
   }

   /**
    * Returns {@code active}
    */
   public boolean isActive()
   {
      return active;
   }

   /**
    * Sets active to {@code false}<br/>
    * <br/>
    * Requires:<br/>
    * For all nodes, there are no empty ports. That is, for the highest filled
    * port (for both inputs and outputs), there are no empty ports below it.<br/>
    */
   public void deactivate()
   {
      if (active)
      {
         active = false;
         for (NodeType i : nodes)
            i.deactivate();
         for (EdgeType c : edges)
            c.deactivate();
      }
      checkRep();
   }
   
}
