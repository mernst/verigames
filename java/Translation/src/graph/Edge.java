package graph;

import static utilities.Misc.ensure;

import checkers.nullness.quals.AssertNonNullAfter;

/**
 * An immutable record type representing an edge for a {@link graph.Graph
 * Graph}.
 * <p>
 * Specification Field: {@code start} : {@code NodeType}
 * // The starting point of {@code this}<br/>
 * Specification Field: {@code startPort} : integer // The port on {@code start}
 * to which {@code this} attaches<br/>
 * Specification Field: {@code end} : {@code NodeType} // The ending point of
 * {@code this}<br/>
 * Specification Field: {@code endPort} : integer // The port on {@code end} to
 * which {@code this} attaches
 * <p>
 * Specification Field: {@code active} : {@code boolean} // {@code true} iff
 * {@code this} can be part of a {@link graph.Graph Graph} that is still under
 * construction. Once {@code active} is set to {@code false}, {@code this}
 * becomes immutable.
 * 
 * @param <NodeType>
 * The type of nodes that {@code this} can attach to.
 * @author Nathaniel Mote
 */
// TODO change "active" to something else
public abstract class Edge<NodeType extends Node<? extends Edge<NodeType>>>
{
   /**
    * Must be not null when an {@code Edge} is deactivated. Equivalently, if an
    * {@code Edge} is not active, this field must be not null.
    * <p>
    * {@code start==null} <--> {@code startPort==-1} <--> start has not been
    * initialized
    */
   private /*@LazyNonNull*/ NodeType start;

   /**
    * Must not be -1 when an {@code Edge} is deactivated. Equivalently, if an
    * {@code Edge} is not active, this field must not be -1.
    * <p>
    * {@code start==null} <--> {@code startPort==-1} <--> start has not been
    * initialized
    */
   private int startPort = -1;

   /**
    * Must be not null when an {@code Edge} is deactivated. Equivalently, if an
    * {@code Edge} is not active, this field must be not null.
    * <p>
    * {@code end==null} <--> {@code endPort==-1} <--> end has not been
    * initialized
    */
   private /*@LazyNonNull*/ NodeType end;

   /**
    * Must not be -1 when an {@code Edge} is deactivated. Equivalently, if an
    * {@code Edge} is not active, this field must not be -1.
    * <p>
    * {@code end==null} <--> {@code endPort==-1} <--> end has not been
    * initialized
    */
   private int endPort = -1;

   private boolean active = true;
   
   private static final boolean CHECK_REP_ENABLED = utilities.Misc.CHECK_REP_ENABLED;
   
   /**
    * Ensures that the representation invariant holds.
    */
   protected void checkRep()
   {
      if (!CHECK_REP_ENABLED)
         return;
      
      // Representation Invariant:
      
      // start == null <--> startPort == -1
      ensure((start == null) == (startPort == -1));
      
      // end == null <--> endPort == null
      ensure((end == null) == (endPort == -1));
      
      /*
       * If !active, start and end must be non-null, and startPort and endPort
       * must not equal -1
       */
      if (!active)
      {
         ensure(start != null);
         ensure(end != null);
         ensure(startPort != -1);
         ensure(endPort != -1);
      }

      /*
       * The port numbers used must be valid port numbers for the nodes used.
       * The default implementation enforces no such restrictions, but
       * subclasses may.
       */

      // Note: Graph is responsible for ensuring that a particular edge's
      // connections match those of the nodes it is connected to (that is, the
      // output edge connected to start at startPort must be this, and likewise
      // for end and endPort).
      //
      // This is because there must be a point in time when the edge is
      // connected to the node, but the node is not connected to the edge, or
      // vice versa, simply because one operation must be done before the other,
      // and checkRep is called from the methods that perform those operations.
   }
   
   /**
    * Returns {@code start}, or {@code null} if {@code start} does not exist
    */
   public /*@Nullable*/ NodeType getStart()
   {
      return start;
   }
   
   /**
    * Returns {@code startPort}<br/>
    * <br/>
    * Requires:<br/>
    * - {@code this} has a start node
    */
   public int getStartPort()
   {
      if (start == null)
         throw new IllegalStateException("No start node");
      return startPort;
   }
   
   /**
    * Returns {@code end}, or {@code null} if {@code end} does not exist
    */
   public /*@Nullable*/ NodeType getEnd()
   {
      return end;
   }
   
   /**
    * Returns {@code endPort}<br/>
    * <br/>
    * Requires:<br/>
    * - {@code this} has an end node
    */
   public int getEndPort()
   {
      if (end == null)
         throw new IllegalStateException("No end node");
      return endPort;
   }
   
   /**
    * Sets {@code start} to the {@code startNode}, replacing {@code start}'s old
    * value, if it exists<br/>
    * 
    * Modifies: {@code this}
    * 
    * @param startNode
    * The node to set to {@code start}. Must not be {@code null}.
    * @param port
    * The port number to set to {@code startPort}. Must be a valid output port
    * number for {@code startNode}. {@link graph.Node Node} does not restrict
    * what ports may be used, but subclasses may.
    */
   @AssertNonNullAfter({ "start" })
   protected void setStart(NodeType startNode, int port)
   {
      if (!active)
         throw new IllegalStateException("Mutation attempted on inactive Edge");
      if (startNode == null)
         throw new IllegalArgumentException("node is null");
      
      this.start = startNode;
      this.startPort = port;
      checkRep();
   }
   
   /**
    * Sets {@code end} to the {@code endNode}, replacing {@code end}'s old
    * value, if it exists<br/>
    * 
    * Modifies: {@code this}
    * 
    * @param endNode
    * The node to set to {@code end}. Must not be {@code null}.
    * @param port
    * The port number to set to {@code endPort}. Must be a valid input port
    * number for {@code endNode}. {@link graph.Node Node} does not restrict
    * what ports may be used, but subclasses may.
    */
   @AssertNonNullAfter({ "end" })
   protected void setEnd(NodeType endNode, int port)
   {
      if (!active)
         throw new IllegalStateException("Mutation attempted on inactive Edge");
      if (endNode == null)
         throw new IllegalArgumentException("node is null");
      
      this.end = endNode;
      this.endPort = port;
      checkRep();
   }
   
   /**
    * Returns {@code active}
    */
   public boolean isActive()
   {
      return active;
   }
   
   /**
    * Sets {@code active} to {@code false}<br/>
    * <br/>
    * Requires:<br/>
    * - {@code this.isActive()}<br/>
    * - start and end nodes exist
    */
   protected void deactivate()
   {
      if (!active)
         throw new IllegalStateException("Mutation attempted on inactive Edge");
      if (getStart() == null)
         throw new IllegalStateException("No start node");
      if (getEnd() == null)
         throw new IllegalStateException("No end node");
      active = false;
      checkRep();
   }

   /**
    * Returns a {@code String} representation of {@code this} that does not
    * include its connections to {@link Node Nodes}.
    */
   protected String shallowToString()
   {
      // by default, just return the ugly Object.toString(), because this
      // implementation doesn't have much identifying information.
      return super.toString();
   }

   @Override
   public String toString()
   {
      String startStr = ((start == null) ? "None" : start.shallowToString());
      String endStr = ((end == null) ? "None" : end.shallowToString());
      return shallowToString() + " -- start: " + startStr + " end: " + endStr;
   }
}
