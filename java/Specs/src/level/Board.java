package level;

import java.util.List;
import java.util.Set;

/**
 * @author: Nathaniel Mote
 * 
 * An ADT representing a board for a verification game. It is essentially a
 * graph where the nodes are Intersections and the edges are Chutes. It stores
 * data in both the nodes and the edges.
 * 
 * @specfield: nodes -- Set<Intersection> // the set of nodes contained in the
 * Graph
 * @specfield: edges -- Set<Chute> // the set of edges contained in the Graph
 * 
 * @specfield: incomingNode -- Intersection // the node representing the top of
 * the board, where all the incoming chutes enter
 * 
 * @specfield: outgoingNode -- Intersection // the node representing the bottom
 * of the board, where all the outgoing chutes exit
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
 * override hashcode and equals to rely on the value of mutable data. Therefore,
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
 * outside the package, but the other information will.
 * 
 * Comments are, of course, welcome.
 */

public class Board
{
   
   /**
    * @requires given node implements eternal equality; if this is the first
    * node to be added, it must have type OUTGOING
    * @modifies this
    * @effects If this does not already contain node, adds node to this
    * @return true iff this did not already contain node
    */
   public boolean addNode(Intersection node)
   {
      throw new RuntimeException("Not yet implemented");
   }
   
   /**
    * @requires this.contains(start); this.contains(end); edge does not have
    * start or end nodes; the given ports on the given nodes are empty
    * @modifies this, start, end, edge
    * @effects creates an edge from startPort on the start node to endPort on
    * the end node. modifies start, end, and edge to reflect their new
    * connections
    */
   public void addEdge(Intersection start, int startPort, Intersection end,
         int endPort, Chute edge)
   {
      throw new RuntimeException("Not yet implemented");
   }
   
   /**
    * @returns the cardinality of Nodes
    */
   public int size()
   {
      throw new RuntimeException("Not yet implemented");
   }
   
   /**
    * @return a Set<Intersection> with all node objects in this graph. The
    * returned set will not be affected by future changes to this object, and
    * changes to the returned set will not affect this object.
    */
   public Set<Intersection> getNodes()
   {
      throw new RuntimeException("Not yet implemented");
   }
   
   /**
    * @return a Set<Chute> with all edge objects in this graph. The returned set
    * will not be affected by future changes to this object, and changes to the
    * returned set will not affect this object.
    */
   public Set<Chute> getEdges()
   {
      throw new RuntimeException("Not yet implemented");
   }
   
   /**
    * @return this Board's incomingNode, or null if it does not have one
    */
   public/* @Nullable */Intersection getIncomingNode()
   {
      throw new RuntimeException("Not yet implemented");
   }
   
   /**
    * @return this Board's outgoingNode, or null if it does not have one
    */
   public/* @Nullable */Intersection getOutgoingNode()
   {
      throw new RuntimeException("Not yet implemented");
   }
   
   /**
    * @return true iff nodes contains elt or edges contains elt
    */
   public boolean contains(Object elt)
   {
      throw new RuntimeException("Not yet implemented");
   }
}
