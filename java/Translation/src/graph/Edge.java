package graph;

import checkers.nullness.quals.AssertNonNullAfter;
import checkers.nullness.quals.LazyNonNull;
import checkers.nullness.quals.Nullable;

/**
 * A mutable edge for {@link graph.Graph Graph}.<br/>
 * <br/>
 * Specification Field: {@code start} : {@code NodeType}
 * // The starting point of {@code this}<br/>
 * Specification Field: {@code startPort} : integer // The port on {@code start}
 * to which {@code this} attaches<br/>
 * Specification Field: {@code end} : {@code NodeType} // The ending point of
 * {@code this}<br/>
 * Specification Field: {@code endPort} : integer // The port on {@code end} to
 * which {@code this} attaches<br/>
 * <br/>
 * Specification Field: {@code active} : {@code boolean} // {@code true} iff
 * {@code this} can be part of a {@link graph.Graph Graph} that is still under
 * construction. Once {@code active} is set to {@code false}, {@code this}
 * becomes immutable.
 * 
 * @param <NodeType>
 * The type of nodes that {@code this} can attach to.
 * @author Nathaniel Mote
 */

public class Edge<NodeType extends Node<? extends Edge<NodeType>>>
{
   private @LazyNonNull NodeType start;
   private int startPort = -1;
   private @LazyNonNull NodeType end;
   private int endPort = -1;

   private boolean active = true;
   
   private static final boolean CHECK_REP_ENABLED = true;
   
   /**
    * Ensures that the representation invariant holds.
    */
   protected void checkRep()
   {
      if (CHECK_REP_ENABLED)
      {
         if (!active)
         {
            ensure(start != null);
            ensure(end != null);
            ensure(startPort != -1);
            ensure(endPort != -1);
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
    * Returns {@code start}, or {@code null} if {@code start} does not exist
    */
   public @Nullable NodeType getStart()
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
   public @Nullable NodeType getEnd()
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
}
