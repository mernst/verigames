package graph;

import java.util.LinkedHashSet;
import java.util.Set;

public class Graph<NodeType extends Node<EdgeType>, EdgeType extends Edge<NodeType>>
{
   
   private static final boolean CHECK_REP_ENABLED = true;
   private Set<NodeType> nodes;
   private Set<EdgeType> edges;
   private boolean active = true;

   public Graph()
   {
      nodes = new LinkedHashSet<NodeType>();
      edges = new LinkedHashSet<EdgeType>();
   }

   /**
    * Ensures that the representation invariant holds
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
    * Adds node to this.nodes.<br/>
    * <br/>
    * Requires:<br/>
    * active;<br/>
    * node.isActive();<br/>
    * given node implements eternal equality;<br/>
    * if this is the first node to be added, it must have type INCOMING;<br/>
    * if this is of Kind INCOMING, there must not already be a node of Kind
    * OUTGOING;<br/>
    * if this is of Kind OUTGOING, there must not already be a node of Kind
    * OUTGOING;<br/>
    * !this.contains(node)<br/>
    * <br/>
    * Modifies: this
    * 
    */
   public void addNode(NodeType node)
   {
      if (!active)
         throw new IllegalStateException("Mutation attempted on an inactive Board");
      if (!node.isActive())
         throw new IllegalStateException("Inactive NodeType added to Board");
      
      if (this.contains(node))
         throw new IllegalArgumentException(
               "A given node object can be added no more than once");
      
      nodes.add(node);
      checkRep();
   }

   /**
    * Adds an edge from startPort on the start node to endPort on the end node.
    * Modifies start, end, and edge to reflect their new connections<br/>
    * <br/>
    * Requires:<br/>
    * active;<br/>
    * start.isActive();<br/>
    * end.isActive();<br/>
    * edge.isActive();<br/>
    * this.contains(start);<br/>
    * this.contains(end);<br/>
    * !this.contains(edge) edge does not have start or end nodes;<br/>
    * the given ports on the given nodes are empty<br/>
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
               "Call to addEdge made with an edge that is already connected to nodes");
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
    * Returns the cardinality of nodes.<br/>
    * <br/>
    * May be more efficient than getNodes().size()
    */
   public int nodesSize()
   {
      return nodes.size();
   }

   /**
    * Returns the cardinality of edges<br/>
    * <br/>
    * May be more efficient than getEdges().size()
    */
   public int edgesSize()
   {
      return edges.size();
   }

   /**
    * Returns a Set<NodeType> with all node objects in this graph. The
    * returned set will not be affected by future changes to this object, and
    * changes to the returned set will not affect this object.
    */
   public Set<NodeType> getNodes()
   {
      return new LinkedHashSet<NodeType>(nodes);
   }

   /**
    * Returns a Set<EdgeType> with all edge objects in this graph. The returned set
    * will not be affected by future changes to this object, and changes to the
    * returned set will not affect this object.
    */
   public Set<EdgeType> getEdges()
   {
      return new LinkedHashSet<EdgeType>(edges);
   }

   /**
    * Returns true iff nodes contains elt or edges contains elt<br/>
    * <br/>
    * May be more efficient than<br/>
    * getNodes().contains(elt) || getEdges.contains(elt)
    */
   public boolean contains(Object elt)
   {
      return nodes.contains(elt) || edges.contains(elt);
   }

   /**
    * Returns active
    */
   public boolean isActive()
   {
      return active;
   }

   /**
    * Sets active to false<br/>
    * <br/>
    * Requires:<br/>
    * all Intersections in nodes and Chutes in edges are in a state in which
    * they can be deactivated
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