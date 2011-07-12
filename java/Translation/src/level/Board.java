package level;

import java.util.HashSet;
import java.util.Set;

import static level.Intersection.Kind;

import checkers.nullness.quals.*;

/**
 * An ADT representing a board for a verification game. It is essentially a
 * graph where the nodes are Intersections and the edges are Chutes. It stores
 * data in both the nodes and the edges.<br/>
 * <br/>
 * Specification Field: nodes -- Set<Intersection> // the set of nodes contained
 * in the Graph<br/>
 * Specification Field: edges -- Set<Chute> // the set of edges contained in the
 * Graph<br/>
 * <br/>
 * Specification Field: incomingNode -- Intersection // the node representing
 * the top of the board, where all the incoming chutes enter<br/>
 * Specification Field: outgoingNode -- Intersection // the node representing
 * the bottom of the board, where all the outgoing chutes exit<br/>
 * 
 * @author Nathaniel Mote
 */

public class Board
{
   private static final boolean CHECK_REP_ENABLED = true;
   
   private @LazyNonNull Intersection incomingNode;
   private @LazyNonNull Intersection outgoingNode;
   
   private Set<Intersection> nodes;
   private Set<Chute> edges;
   
   /**
    * Ensures that the representation invariant holds
    */
   private void checkRep()
   {
      if (CHECK_REP_ENABLED)
      {
         // Representation Invariant:
         
         // nodes != null:
         ensure(nodes != null);
         // edges != null
         ensure(edges != null);
         
         // if nodes.size == 1, its element, i, must be of type INCOMING
         if (nodes.size() == 1)
         {
            ensure(nodes.iterator().next().getIntersectionKind() == Kind.INCOMING);
         }
         
         for (Intersection i : nodes)
         {
            if (i.getIntersectionKind() == Kind.INCOMING)
            {
               // nodes may contain no more than one element of type INCOMING
               ensure(incomingNode == i);
            }
            else if (i.getIntersectionKind() == Kind.OUTGOING)
            {
               // nodes may contain no more than one element of type OUTGOING
               ensure(outgoingNode == i);
            }
         }
         
         // incomingNode != null <--> there exists an element i in nodes such
         // that
         // i.getIntersectionType() == INCOMING
         ensure((incomingNode == null) || nodes.contains(incomingNode));
         // outgoingNode != null <--> there exists an element i in nodes such
         // that
         // i.getIntersectionType() == OUTGOING
         ensure((outgoingNode == null) || nodes.contains(outgoingNode));
         
         // for all n in nodes; e in edges:
         // e.getStart() == n <--> n.getOutputChute(e.getStartPort()) == e
         // e.getEnd() == n <--> n.getInputChute(e.getEndPort()) == e
         for (Chute e : edges)
         {
            Intersection n = e.getStart();
            // e.getStart() == n --> n.getOutputChute(e.getStartPort()) == e
            ensure(n.getOutputChute(e.getStartPort()) == e);
            
            n = e.getEnd();
            // e.getEnd() == n --> n.getInputChute(e.getEndPort()) == e
            ensure(n.getInputChute(e.getEndPort()) == e);
         }
         
         for (Intersection n : nodes)
         {
            
            // This approach stops verifying after encountering the first port
            // with a null value. Therefore, it may not always check every
            // existing output port
            
            Chute e = n.getOutputChute(0);
            for (int i = 0; e != null; e = n.getOutputChute(++i))
            {
               // e.getStart() == n <-- n.getOutputChute(e.getStartPort()) == e
               ensure(i == e.getStartPort());
               ensure(e.getStart() == n);
            }
            
            e = n.getInputChute(0);
            for (int i = 0; e != null; e = n.getInputChute(++i))
            {
               // e.getEnd() == n <-- n.getInputChute(e.getEndPort()) == e
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
    * Creates a new, empty board
    */
   public Board()
   {
      nodes = new HashSet<Intersection>();
      edges = new HashSet<Chute>();
      checkRep();
   }
   
   /**
    * Adds node to this.nodes.<br/>
    * <br/>
    * Requires:<br/>
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
   // TODO fix error messages
   public void addNode(Intersection node)
   {
      if (incomingNode == null && node.getIntersectionKind() != Kind.INCOMING)
         throw new IllegalArgumentException(
               "First node in Board must be of kind INCOMING");
      
      if (incomingNode != null && node.getIntersectionKind() == Kind.INCOMING)
         throw new IllegalArgumentException(
               "No more than one node can be of kind INCOMING");
      
      if (outgoingNode != null && node.getIntersectionKind() == Kind.OUTGOING)
         throw new IllegalArgumentException(
               "No more than one node can be of kind OUTGOING");
      
      if (this.contains(node))
         throw new IllegalArgumentException(
               "A given node object can be added no more than once");
      
      if (node.getIntersectionKind() == Kind.INCOMING)
         incomingNode = node;
      
      else if (node.getIntersectionKind() == Kind.OUTGOING)
         outgoingNode = node;
      
      nodes.add(node);
      checkRep();
   }
   
   /**
    * Adds an edge from startPort on the start node to endPort on the end
    * node. Modifies start, end, and edge to reflect their new connections<br/>
    * <br/>
    * Requires:<br/>
    * this.contains(start);<br/>
    * this.contains(end);<br/>
    * !this.contains(edge) edge does not have start or end nodes;<br/>
    * the given ports on the given nodes are empty<br/>
    */
   // TODO fix error messages
   public void addEdge(Intersection start, int startPort, Intersection end,
         int endPort, Chute edge)
   {
      if (!this.contains(start))
         throw new IllegalArgumentException(
               "Call to addEdge made with a start node that is not in this Board");
      if (!this.contains(end))
         throw new IllegalArgumentException(
               "Call to addEdge made with a end node that is not in this Board");
      if (this.contains(edge))
         throw new IllegalArgumentException(
               "Call to addEdge made with an edge that is already in this Board");
      if (edge.getStart() != null || edge.getEnd() != null)
         throw new IllegalArgumentException(
               "Call to addEdge made with an edge that is already connected to nodes");
      if (start.getOutputChute(startPort) != null)
         throw new IllegalArgumentException(
               "Call to addEdge made with a start node that is already connected to an edge on the given port");
      if (end.getOutputChute(endPort) != null)
         throw new IllegalArgumentException(
               "Call to addEdge made with an end node that is already connected to an edge on the given port");
      
      edges.add(edge);
      
      start.setOutputChute(edge, startPort);
      end.setInputChute(edge, endPort);
      
      edge.setStart(start, startPort);
      edge.setEnd(end, endPort);
      
      checkRep();
   }
   
   /**
    * Returns the cardinality of nodes
    */
   public int nodesSize()
   {
      return nodes.size();
   }
   
   /**
    * Returns the cardinality of edges
    */
   public int edgesSize()
   {
      return edges.size();
   }
   
   /**
    * Returns a Set<Intersection> with all node objects in this graph. The
    * returned set will not be affected by future changes to this object, and
    * changes to the returned set will not affect this object.
    */
   public Set<Intersection> getNodes()
   {
      return new HashSet<Intersection>(nodes);
   }
   
   /**
    * Returns a Set<Chute> with all edge objects in this graph. The returned set
    * will not be affected by future changes to this object, and changes to the
    * returned set will not affect this object.
    */
   public Set<Chute> getEdges()
   {
      return new HashSet<Chute>(edges);
   }
   
   /**
    * Returns this Board's incomingNode, or null if it does not have one
    */
   public/* @Nullable */Intersection getIncomingNode()
   {
      return incomingNode;
   }
   
   /**
    * Returns this Board's outgoingNode, or null if it does not have one
    */
   public/* @Nullable */Intersection getOutgoingNode()
   {
      return outgoingNode;
   }
   
   /**
    * Returns true iff nodes contains elt or edges contains elt
    */
   public boolean contains(Object elt)
   {
      return nodes.contains(elt) || edges.contains(elt);
   }
}
