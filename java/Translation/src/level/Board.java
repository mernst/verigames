package level;

import graph.Graph;

import java.util.Set;

import level.Intersection.Kind;
import checkers.nullness.quals.LazyNonNull;

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
 * <br/>
 * Specification Field: active : boolean // true iff this can be part of a
 * structure that is still under construction. once active is set to false, this
 * becomes immutable.<br/>
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
    * Creates a new, empty board
    */
   public Board()
   {
      checkRep();
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
