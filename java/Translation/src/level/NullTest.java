package level;

/**
 * @author Nathaniel Mote
 * 
 * An Intersection subclass that only represents NULL_TEST kinds of
 * Intersection.
 * 
 */

public class NullTest extends Intersection
{
   
   /**
    * @effects creates a new Intersection of kind NULL_TEST
    */
   public NullTest()
   {
      super(Kind.NULL_TEST);
   }
   
   /**
    * return true iff kind is NULL_TEST
    */
   @Override protected boolean checkIntersectionKind(Kind kind)
   {
      // this implementation supports only NULL_TEST
      return kind == Kind.NULL_TEST;
   }
   
   /**
    * @return true to indicate that this is of kind NULL_TEST
    */
   @Override public boolean isNullTest()
   {
      return true;
   }
   
   /**
    * @return this
    */
   @Override public NullTest asNullTest()
   {
      return this;
   }
   
   
}
