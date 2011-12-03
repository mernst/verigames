package utilities;

/**
 * A class containing miscellaneous utilities used in implementation of the
 * packages. Not for use by clients.
 */
public class Misc
{
   /**
    * Intended to be a substitute for assert, except I don't want to have to
    * make sure the -ea flag is turned on in order to get these checks.
    */
   public static void ensure(boolean value)
   {
      if (!value)
         throw new AssertionError();
   }

   /**
    * Controls whether checkRep is run in various classes in various packages.
    * However, some classes may ignore this value in favor of their own, for
    * greater granularity.
    */
   public static final boolean CHECK_REP_ENABLED = true;
}