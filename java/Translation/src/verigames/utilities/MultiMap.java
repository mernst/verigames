package verigames.utilities;

import java.util.*;

/**
 * A lightweight implementation of a {@code MultiMap}. That is, each key can map
 * to multiple values.
 * <p>
 * This implementation is backed by a {@code HashMap} and {@code HashSet}s so
 * that operations can be done in constant time.
 * 
 * @param <K>
 * The type of they keys
 * @param <V>
 * The type of the values
 *
 * @author Nathaniel Mote
 */
public class MultiMap<K,V>
{
   private Map<K, Set<V>> delegate;

   /**
    * Creates a new, empty {@code MultiMap}
    */
   public MultiMap()
   {
      delegate = new LinkedHashMap<K, Set<V>>();
   }

   /**
    * Adds a mapping from {@code key} to {@code value}. Does not remove any
    * previous mappings.
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
    * Returns an unmodifiable view on a set containing all values to which
    * {@code key} maps. Returns an empty set if {@code key} maps to no values.
    * 
    * @param key
    */
   // TODO make results consistent -- right now, if the key exists, the returned
   // set will change as values are added, but if the key does not exist, the
   // returned map will not change.
   public Set<V> get(K key)
   {
      Set<V> ret = delegate.get(key);
      if (ret != null)
         return Collections.unmodifiableSet(ret);
      else
         return Collections.emptySet();
   }
}
