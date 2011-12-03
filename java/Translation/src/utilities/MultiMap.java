package utilities;

import java.util.Set;
import java.util.Map;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;

/**
 * A lightweight implementation of a MultiMap. That is, each key can map
 * to multiple values.
 * 
 * @param <K>
 * The type of they keys
 * @param <V>
 * The type of the values
 */
public class MultiMap<K,V>
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
