package level;

import java.util.Set;

/**
 * @author: Nathaniel Mote
 * 
 * An ADT representing a board for a verification game. It is essentially a
 * graph where the nodes are Intersections and the edges are Chutes. It stores
 * data in both the nodes and the edges.
 * 
 * @specfield: Nodes -- Set<Intersection> // the set of nodes contained in the
 * Graph
 * @specfield: Edges -- Set<Chute> // the set of edges contained in the Graph
 * 
 * @specfield: incomingNode -- Intersection // the node representing the top of
 * the board, where all the incoming chutes enter
 * 
 * @specfield: outgoingNode -- Intersection // the node representing the bottom
 * of the board, where all the outgoing chutes exit
 */

public class Board
{
   
   /**
    * @requires given node implements eternal equality; if this is the first
    * node, it must have type OUTGOING
    * @modifies this
    * @effects If this does not already contain node, adds node to this
    * @returns true iff this did not already contain node
    */
   public boolean addNode(Intersection node)
   {
      throw new RuntimeException("Not yet implemented");
   }
   
   /**
    * @requires this.contains(start); this.contains(end);
    * @modifies this, start, end, edge
    * @effects creates an edge from startPort on the start node to endPort on
    * the end node. modifies start, end, and edge to reflect their new
    * connections
    * @returns true iff this did not already contain an edge from start to end
    */
   public boolean addEdge(Intersection start, int startPort, Intersection end,
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
    * @returns a Set<Intersection> with all node objects in this graph, in no
    * particular order. The returned list will not be affected by future changes
    * to this object, and changes to the returned list will not affect this
    * object.
    */
   public Set<Intersection> getNodes()
   {
      throw new RuntimeException("Not yet implemented");
   }
}
