package utilities;

/**
 * An immutable record type representing a pair of arbitrary elements.
 */
public class Pair<A,B>
{
   private final A first;
   private final B second;

   public Pair(A first, B second)
   {
      this.first = first;
      this.second = second;
   }

   public A getFirst()
   {
      return first;
   }

   public B getSecond()
   {
      return second;
   }
}
