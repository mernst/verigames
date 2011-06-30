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
   
   // TODO implement features specific to NullTest:
   // how to set the chutes? regularly, or through new setters?
   // probably regularly so that it's still usable through Board
   
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
   
   /**
    * @return the Chute associated with the null branch of the test. That is,
    * after this node, only null balls will roll down this chute.
    */
   public Chute getNullChute()
   {
      throw new RuntimeException("Not yet implemented");
   }
   
   /**
    * @return the Chute associated with the not-null branch of the test. That
    * is, after this node, only non-null balls will roll down this chute.
    */
   public Chute getNonNullChute()
   {
      throw new RuntimeException("Not yet implemented");
   }
   
}
