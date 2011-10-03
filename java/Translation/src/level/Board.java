package level;

import static utilities.Misc.ensure;

import graph.Graph;

import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.Map;
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
   private static final boolean CHECK_REP_ENABLED = utilities.Misc.CHECK_REP_ENABLED;
   
   @LazyNonNull Intersection incomingNode;
   @LazyNonNull Intersection outgoingNode;
   
   private final MultiBiMap<String, Chute> nameToChutes;
   
   /**
    * A lightweight implementation of a MultiBiMap. That is, each key can map to
    * multiple values, and an inverse view of the map can be provided.
    */
   private static class MultiBiMap<K,V>
   {
      /**
       * A lightweight implementation of a MultiMap. That is, each key can map
       * to multiple values.
       * 
       * @param <K>
       * The type of they keys
       * @param <V>
       * The type of the values
       */
      private static class MultiMap<K,V>
      {
         private Map<K, Set<V>> delegate;

         /**
          *  Creates a new, empty {@code MultiMap}
          */
         public MultiMap()
         {
            delegate = new LinkedHashMap<K, Set<V>>();
         }

         /**
          * Adds a mapping from {@code key} to {@code value}. Does not remove
          * any previous mappings.
          * 
          * @param key
          * @param value
          */
         public void put(K key, V value)
         {
            if (delegate.containsKey(key))
            {
               delegate.get(key).add(value);
            }
            else
            {
               Set<V> values = new LinkedHashSet<V>();
               values.add(value);
               delegate.put(key, values);
            }
         }

         /**
          * Returns a set containing all values to which {@code key} maps
          * 
          * @param key
          */
         public Set<V> get(K key)
         {
            Set<V> ret = delegate.get(key);
            if (ret != null)
               return ret;
            else
               return new LinkedHashSet<V>();
         }
      }
      
      private MultiMap<K, V> forward;
      private MultiMap<V, K> backward;

      private MultiBiMap<V, K> inverse;

      /**
       * Creates a new, empty, MultiBiMap
       */
      public MultiBiMap()
      {
         forward = new MultiMap<K, V>();
         backward = new MultiMap<V, K>();
         inverse = new MultiBiMap<V, K>(backward, forward, this);
      }

      /**
       * Creates a new MultiBiMap with the given fields. Used exclusively for
       * constructing the inverse view of a MultiBiMap created with the
       * {@linkplain #Board.MultiBiMap() public constructor}
       * 
       * @param forward
       * @param backward
       * @param inverse
       */
      private MultiBiMap(MultiMap<K, V> forward, MultiMap<V, K> backward, MultiBiMap<V, K> inverse)
      {
         this.forward = forward;
         this.backward = backward;
         this.inverse = inverse;
      }

      /**
       * Returns a set of all the values to which {@code key} maps
       * 
       * @param key
       */
      public Set<V> get(K key)
      {
         return forward.get(key);
      }

      /**
       * Adds a mapping from {@code key} to {@code value}. Does not remove any
       * previous mappings
       * 
       * @param key
       * @param value
       */
      public void put(K key, V value)
      {
         forward.put(key, value);
         backward.put(value, key);
      }

      /**
       * Returns an inverse view of {@code this}. The returned map is backed by
       * {@code this}, so changes in one are reflected in the other.
       */
      public MultiBiMap<V, K> inverse()
      {
         return inverse;
      }
   }

   /**
    * Ensures that the representation invariant holds
    */
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
      
      // if this is inactive
      if (!this.isActive())
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
   public/* @Nullable */Intersection getIncomingNode()
   {
      return incomingNode;
   }
   
   /**
    * Returns {@code this}'s {@code outgoingNode}, or {@code null} if it does not
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
      
      super.addNode(node);
   }
}
