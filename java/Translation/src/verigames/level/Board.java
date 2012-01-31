package verigames.level;

import static verigames.utilities.Misc.ensure;

import verigames.graph.Graph;
import verigames.level.Intersection.Kind;
import verigames.utilities.MultiBiMap;

import java.util.Set;

/**
 * A board for Pipe Jam. It is a {@link verigames.graph.Graph Graph} with {@link
 * Intersection}s as nodes and {@link Chute}s as edges. It stores data in both
 * the nodes and the edges.
 * <p>
 * It must be a Directed Acyclic Graph (DAG).
 * <p>
 * The first node added must be an {@code Intersection} of {@link
 * Intersection.Kind Kind} {@link Intersection.Kind#INCOMING INCOMING}.
 * <p>
 * {@code Chute} names are stored here because there may not be a one-to-one
 * relation between {@code Chute}s and variable names. Most names will have
 * multiple {@code Chute}s, and some {@code Chute}s will have multiple names.
 * Additionally, some {@code Chute}s may have no name at all, and simply
 * represent the type of an unnamed expression.
 * <p>
 * Specification Field: {@code incomingNode} -- {@link Intersection}
 * // the node representing the top of the board, where all the incoming chutes
 * enter. {@code Intersections} of {@code Kind} can be the starting point for an
 * arbitrary number of chutes.
 * <p>
 * Specification Field: {@code outgoingNode} -- {@link Intersection}
 * // the node representing the bottom of the board, where all the outgoing
 * chutes exit. {@code Intersections} of {@code Kind} can be the starting point
 * for an arbitrary number of chutes.
 *
 * @author Nathaniel Mote
 */

public class Board extends Graph<Intersection, Chute>
{
   private static final boolean CHECK_REP_ENABLED = verigames.utilities.Misc.CHECK_REP_ENABLED;
   
   private /*@LazyNonNull*/ Intersection incomingNode;
   private /*@LazyNonNull*/ Intersection outgoingNode;
   
   private final MultiBiMap<String, Chute> nameToChutes;
   

   /**
    * Ensures that the representation invariant holds
    */
   @Override
   protected void checkRep()
   {
      super.checkRep();
      
      if (!CHECK_REP_ENABLED)
         return;
      
      Set<Intersection> nodes = getNodes();
      
      // Representation Invariant:

      // if incomingNode is not null, its Kind must be INCOMING
      if (incomingNode != null)
         ensure (incomingNode.getIntersectionKind() == Kind.INCOMING);

      // if outgoingNode is not null, its Kind must be OUTGOING
      if (outgoingNode != null)
         ensure (outgoingNode.getIntersectionKind() == Kind.OUTGOING);

      // if nodes is non-empty, incomingNode must be non-null
      ensure(nodes.isEmpty() || incomingNode != null);
      
      for (Intersection i : nodes)
      {
         if (i.getIntersectionKind() == Kind.INCOMING)
         {
            // nodes may contain no more than one Node of Kind INCOMING
            ensure(incomingNode == i);
         }
         else if (i.getIntersectionKind() == Kind.OUTGOING)
         {
            // nodes may contain no more than one Node of Kind OUTGOING
            ensure(outgoingNode == i);
         }
      }
      
      // incomingNode != null <--> nodes contains incomingNode
      ensure((incomingNode != null) == nodes.contains(incomingNode));
      // outgoingNode != null <--> nodes contains outgoingNode
      ensure((outgoingNode != null) == nodes.contains(outgoingNode));
      
      // if this is constructed
      if (!this.underConstruction())
      {
         // incomingNode and outgoingNode must be non-null
         ensure(incomingNode != null);
         ensure(outgoingNode != null);
      }
   }
   
   /**
    * Creates a new, empty {@code Board}
    */
   public Board()
   {
      nameToChutes = new MultiBiMap<String, Chute>();
      checkRep();
   }
   
   public void addChuteName(Chute c, String name)
   {
      nameToChutes.put(name, c);
   }
   
   public Set<String> getChuteNames(Chute c)
   {
      return nameToChutes.inverse().get(c);
   }
   
   public Set<Chute> getNameChutes(String name)
   {
      return nameToChutes.get(name);
   }
   
   /**
    * Returns {@code this}'s {@code incomingNode}, or {@code null} if it does not
    * have one
    */
   public /*@Nullable*/ Intersection getIncomingNode()
   {
      return incomingNode;
   }
   
   /**
    * Returns {@code this}'s {@code outgoingNode}, or {@code null} if it does not
    * have one
    */
   public /*@Nullable*/ Intersection getOutgoingNode()
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
               "First node in Board is not of kind INCOMING: " + node);
      
      if (node.getIntersectionKind() == Kind.INCOMING)
      {
         if (incomingNode != null)
            throw new IllegalArgumentException(
                  "Second INCOMING node added (no more than one is legal): " +
                  node);

         incomingNode = node;
      }

      else if (node.getIntersectionKind() == Kind.OUTGOING)
      {
         if (outgoingNode != null)
            throw new IllegalArgumentException(
                  "Second OUTGOING node added (no more than one is legal): " +
                  node);

         outgoingNode = node;
      }

      if (node.getBoard()!=null) {
          throw new IllegalArgumentException(
                  "Node is already assigned to a board: " + node);
      } else {
          node.setBoard(this);
      }

      super.addNode(node);
   }
}