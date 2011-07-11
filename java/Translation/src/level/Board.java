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
 * Specification Field: nodes -- Set<Intersection> // the set of nodes contained in the
 * Graph<br/>
 * Specification Field: edges -- Set<Chute> // the set of edges contained in the Graph<br/>
 * <br/>
 * Specification Field: incomingNode -- Intersection // the node representing the top of
 * the board, where all the incoming chutes enter<br/>
 * Specification Field: outgoingNode -- Intersection // the node representing the bottom
 * of the board, where all the outgoing chutes exit<br/>
 * 
 * @author: Nathaniel Mote
 */

/*
 * Notes:
 * 
 * - This class suffers from representation exposure. Any of the Chutes and
 * Intersections could be modified by clients. I think it's the best option,
 * though.
 * 
 * My reasoning is as follows:
 * 
 * We need a way to refer to specific Chute and Intersection objects. We cannot
 * do this by value, for two reasons. The first is that there may be Chutes and
 * Intersections that are identical except for their UID. The second is that
 * since both are mutable, and we wish to use them in Sets and Maps, we can't
 * override hashCode and equals to rely on the value of mutable data. Therefore,
 * we can't use the Collections' built in search functions, because they rely on
 * equals. Therefore, the only way to find a specific object would be to do a
 * linear search on the objects, comparing values.
 * 
 * This leaves us with two options for referring to specific objects. We could
 * use their UIDs (a feature of Chute and Intersection) or refer to them by
 * reference. These two options would be identical, except that in the case of
 * UID, outside users would not be able to create or modify the objects. This
 * means that the responsibility for doing that would fall on this class, which
 * would lead to bloat, in my opinion.
 * 
 * I'm going to try to mitigate the issue by making the relevant mutations on
 * Chutes and Intersections protected, so they can only be accessed from within
 * the package. I think that will give us the best of both worlds, because the
 * graph structure information stored in these objects won't be accessible
 * outside the package, but the other information will. However, problems could
 * still arise if the same Intersection or Chute is present in multiple Boards
 * 
 * Comments are, of course, welcome.
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
         
         boolean incomingEncountered = false;
         boolean outgoingEncountered = false;
         for (Intersection i : nodes)
         {
            if (i.getIntersectionKind() == Kind.INCOMING)
            {
               // nodes may contain no more than one element of type INCOMING
               ensure(!incomingEncountered);
               incomingEncountered = true;
            }
            else if (i.getIntersectionKind() == Kind.OUTGOING)
            {
               // nodes may contain no more than one element of type OUTGOING
               ensure(!outgoingEncountered);
               outgoingEncountered = true;
            }
         }
         
         // incomingNode != null <--> there exists an element i in nodes such
         // that
         // i.getIntersectionType() == INCOMING
         ensure((incomingNode != null) == incomingEncountered);
         // outgoingNode != null <--> there exists an element i in nodes such
         // that
         // i.getIntersectionType() == OUTGOING
         ensure((outgoingNode != null) == outgoingEncountered);
         
         // for all n in nodes; e in edges:
         for (Intersection n : nodes)
         {
            for (Chute e : edges)
            {
               // e.getStart() == n <--> n.getOutputChute(e.getStartPort()) == e
               ensure((e.getStart() == n) == (n
                     .getOutputChute(e.getStartPort()) == e));
               // e.getEnd() == n <--> n.getInputChute(e.getEndPort()) == e
               ensure((e.getEnd() == n) == (n.getInputChute(e.getEndPort()) == e));
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
    * Adds node to this.nodes<br/>
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
    * Modifies this
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
    * Creates an edge from startPort on the start node to endPort on the end
    * node. modifies start, end, and edge to reflect their new connections<br/>
    * <br/>
    * Requires:<br/>
    * this.contains(start);<br/>
    * this.contains(end);<br/>
    * !this.contains(edge) edge does not have start or end nodes;<br/>
    * the given ports on the given nodes are empty<br/>
    * <br/>
    * Modifies: this, start, end, edge
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
