package level;

import graph.Graph;

import java.util.Set;

import level.Intersection.Kind;
import checkers.nullness.quals.LazyNonNull;

/**
 * A board for Pipe Jam. It is a {@link graph.Graph Graph} with
 * {@link Intersection}s as nodes and {@link Chute}s as edges. It stores data in
 * both the nodes and the edges.<br/>
 * <br/>
 * It is a Directed Acyclic Graph (DAG). <br/>
 * <br/>
 * Specification Field: {@code incomingNode} -- {@link Intersection}
 * // the node representing the top of the board, where all the incoming chutes
 * enter<br/>
 * Specification Field: {@code outgoingNode} -- {@link Intersection}
 * // the node representing the bottom of the board, where all the outgoing
 * chutes exit<br/>
 * <br/>
 * 
 * @author Nathaniel Mote
 */

public class Board extends Graph<Intersection, Chute>
{
   private static final boolean CHECK_REP_ENABLED = true;
   
   @LazyNonNull Intersection incomingNode;
   @LazyNonNull Intersection outgoingNode;
   
   /**
    * Ensures that the representation invariant holds
    */
   protected void checkRep()
   {
      super.checkRep();
      
      if (CHECK_REP_ENABLED)
      {
         // Representation Invariant:
         Set<Intersection> nodes = getNodes();
         
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
      }
   }
   
   /**
    * Intended to be a substitute for assert, except I don't want to have to
    * make sure the -ea flag is turned on in order to get these checks.
    */
   void ensure(boolean value)
   {
      if (!value)
         throw new AssertionError();
   }
   
   /**
    * Creates a new, empty {@code Board}
    */
   public Board()
   {
      checkRep();
   }
   
   /**
    * Returns {@code this}' {@code incomingNode}, or {@code null} if it does not
    * have one
    */
   public/* @Nullable */Intersection getIncomingNode()
   {
      return incomingNode;
   }
   
   /**
    * Returns {@code this}' {@code outgoingNode}, or {@code null} if it does not
    * have one
    */
   public/* @Nullable */Intersection getOutgoingNode()
   {
      return outgoingNode;
   }
   
   /**
    * Adds {@code node} to {@code this}.<br/>
    * <br/>
    * Requires:<br/>
    * - if {@link #getNodes() getNodes()}{@code .isEmpty()}, {@code node} must have
    * {@link Intersection.Kind Kind} {@link Intersection.Kind#INCOMING INCOMING}<br/>
    * - if {@link #getIncomingNode} {@code != null} then {@code node} must not
    * have {@link Intersection.Kind Kind} {@link Intersection.Kind#INCOMING
    * INCOMING}<br/>
    * - if {@link #getOutgoingNode} {@code != null} then {@code node} must not
    * have {@link Intersection.Kind Kind} {@link Intersection.Kind#OUTGOING
    * OUTGOING}<br/>
    * 
    * @param node
    * The {@link Intersection} to add.
    */
   @Override
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
      
      if (node.getIntersectionKind() == Kind.INCOMING)
         incomingNode = node;
      
      else if (node.getIntersectionKind() == Kind.OUTGOING)
         outgoingNode = node;
      
      super.addNode(node);
   }
}
