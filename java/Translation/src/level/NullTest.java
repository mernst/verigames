package level;

import checkers.nullness.quals.Nullable;

/**
 * An Intersection subclass that represents NULL_TEST kinds of Intersection.<br/>
 * <br/>
 * The output chute in port 0 represents the "not null" branch of this test<br/>
 * <br/>
 * The output chute in port 1 represents the "null" branch of this test<br/>
 * <br/>
 * Note that the requirements on the chutes imposed by the setNullChute and
 * setNonNullChute methods can be circumvented by using the super-class
 * accessors. This is not recommended, and, when checkRep is enabled for
 * debugging, could lead to a failure.<br/>
 * 
 * @author Nathaniel Mote
 */

public class NullTest extends Intersection
{
   
   /*
    * Representation Invariant (in addition to the superclass rep invariant):
    * 
    * The output chute in port 0 is the "non-null" chute and must be uneditable
    * and narrow
    * 
    * The output chute in port 1 is the "null" chute and must be uneditable and
    * wide
    */
   
   private static final boolean CHECK_REP_ENABLED = true;
   
   /**
    * Checks that the representation invariant holds
    */
   @Override
   protected void checkRep()
   {
      super.checkRep();
      
      if (CHECK_REP_ENABLED)
      {
         Chute nonNullChute = getNonNullChute();
         if (nonNullChute != null
               && (nonNullChute.isEditable() || !nonNullChute.isNarrow()))
            throw new RuntimeException(
                  "NullTest's NonNull chute does not have the proper settings");
         
         Chute nullChute = getNullChute();
         if (nullChute != null
               && (nullChute.isEditable() || nullChute.isNarrow()))
            throw new RuntimeException(
                  "NullTest's Null chute does not have the proper settings");
      }
   }
   
   /**
    * Creates a new Intersection of kind NULL_TEST
    */
   protected NullTest()
   {
      super(Kind.NULL_TEST);
      checkRep();
   }
   
   /**
    * Returns true iff kind is NULL_TEST
    */
   @Override protected boolean checkIntersectionKind(Kind kind)
   {
      // this implementation supports only NULL_TEST
      return kind == Kind.NULL_TEST;
   }
   
   /**
    * Returns true to indicate that this is of kind NULL_TEST
    */
   @Override public boolean isNullTest()
   {
      return true;
   }
   
   /**
    * Returns this
    */
   @Override public NullTest asNullTest()
   {
      return this;
   }
   
   /**
    * Returns the Chute (or null if none exists) associated with the null branch
    * of the test. That is, after this node, only null balls will roll down this
    * chute.
    */
   public @Nullable Chute getNullChute()
   {
      return getOutputChute(1);
   }
   
   /**
    * Sets the given Chute to be the null branch of this null test<br/>
    * <br/>
    * Requires: !chute.isEditable; !chute.isNarrow(), narrowness will not change
    * in the future<br/>
    * <br/>
    * Modifies: this<br/>
    */
   protected void setNullChute(Chute chute)
   {
      if (chute.isEditable())
         throw new IllegalArgumentException(
               "Chute passed to setNullChute must not be editable");
      if (chute.isNarrow())
         throw new IllegalArgumentException(
               "Chute passed to setNullChute must not be narrow");
      setOutputChute(chute, 1);
      checkRep();
   }
   
   /**
    * Returns the Chute (or null if none exists) associated with the not-null
    * branch of the test. That is, after this node, only non-null balls will
    * roll down this chute.
    */
   public @Nullable Chute getNonNullChute()
   {
      return getOutputChute(0);
   }
   
   /**
    * sets the given Chute to be the not-null branch of this null test<br/>
    * <br/>
    * Requires:<br/>
    * !chute.isEditable;<br/>
    * chute.isNarrow(), narrowness will not change in the future<br/>
    * <br/>
    * Modifies: this
    */
   protected void setNonNullChute(Chute chute)
   {
      if (chute.isEditable())
         throw new IllegalArgumentException(
               "Chute passed to setNonNullChute must not be editable");
      if (!chute.isNarrow())
         throw new IllegalArgumentException(
               "Chute passed to setNonNullChute must be narrow");
      
      setOutputChute(chute, 0);
      checkRep();
   }
   
}
