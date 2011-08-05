package level;

import checkers.nullness.quals.Nullable;

/**
 * An {@link Intersection} subclass that represents
 * {@link Intersection.Kind#NULL_TEST NULL_TEST} {@link Intersection.Kind Kind}s
 * of {@code Intersection}.<br/>
 * <br/>
 * The output chute in port 0 represents the "not null" branch of this test<br/>
 * <br/>
 * The output chute in port 1 represents the "null" branch of this test<br/>
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
    * Creates a new {@link Intersection} of {@link Intersection.Kind Kind}
    * {@link Intersection.Kind#NULL_TEST NULL_TEST}
    */
   protected NullTest()
   {
      super(Kind.NULL_TEST);
      checkRep();
   }
   
   /**
    * Returns {@code true} iff {@code kind} is
    * {@link Intersection.Kind#NULL_TEST NULL_TEST}, indicating that this
    * implementation supports only {@code NULL_TEST}.
    * 
    * @param kind
    */
   @Override protected boolean checkIntersectionKind(Kind kind)
   {
      // this implementation supports only NULL_TEST
      return kind == Kind.NULL_TEST;
   }
   
   /**
    * Returns {@code true} to indicate that {@code this} is a {@code NullTest}.
    */
   @Override public boolean isNullTest()
   {
      return true;
   }
   
   /**
    * Returns {@code this}
    */
   @Override public NullTest asNullTest()
   {
      return this;
   }
   
   /**
    * Returns the {@link Chute} (or {@code null} if none exists) associated with
    * the null branch of this test. That is, in the game, after reaching this
    * {@link Intersection}, only "null balls" will roll down the returned
    * {@link Chute}.
    */
   public @Nullable Chute getNullChute()
   {
      return getOutput(1);
   }
   
   /**
    * Sets {@code chute} to the null branch<br/>
    * <br/>
    * Requires:<br/>
    * - {@link Chute#isEditable() !chute.isEditable()}<br/>
    * - {@link Chute#isNarrow() !chute.isNarrow()}<br/>
    * <br/>
    * Modifies: {@code this}<br/>
    * @param chute
    */
   protected void setNullChute(Chute chute)
   {
      if (chute.isEditable())
         throw new IllegalArgumentException(
               "Chute passed to setNullChute must not be editable");
      if (chute.isNarrow())
         throw new IllegalArgumentException(
               "Chute passed to setNullChute must not be narrow");
      setOutput(chute, 1);
      checkRep();
   }
   
   /**
    * Returns the {@link Chute} (or {@code null} if none exists) associated with
    * the not-null branch of this test. That is, in the game, after reaching
    * this {@link Intersection}, only "non-null balls" will roll down the
    * returned {@link Chute}.
    */
   public @Nullable Chute getNonNullChute()
   {
      return getOutput(0);
   }
   
   /**
    * Sets {@code chute} to the not-null branch<br/>
    * <br/>
    * Requires:<br/>
    * - {@link Chute#isEditable() !chute.isEditable()}<br/>
    * - {@link Chute#isNarrow() chute.isNarrow()}<br/>
    * <br/>
    * Modifies: {@code this}<br/>
    * @param chute
    */
   protected void setNonNullChute(Chute chute)
   {
      if (chute.isEditable())
         throw new IllegalArgumentException(
               "Chute passed to setNonNullChute must not be editable");
      if (!chute.isNarrow())
         throw new IllegalArgumentException(
               "Chute passed to setNonNullChute must be narrow");
      
      setOutput(chute, 0);
      checkRep();
   }
   
   // TODO override setOutput to call setNull and setNonNull, update
   // documentation so this is ok
}
