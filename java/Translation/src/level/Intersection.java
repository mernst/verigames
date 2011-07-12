package level;

import java.util.ArrayList;
import java.util.List;

import checkers.nullness.quals.Nullable;

/**
 * A mutable ADT representing the intersections between chutes.<br/>
 * <br/>
 * It is mutable so that chutes can be added and removed to it.<br/>
 * <br/>
 * Uses eternal equality so that it can be used in Collections while maintaining
 * mutability<br/>
 * <br/>
 * Specification Field: kind : Intersection.Kind // represents which kind of
 * intersection this is<br/>
 * <br/>
 * Specification Field: inputChutes : List<Chute> // represents the ordered set
 * of input chutes (the index of a given Chute represents the port at which it
 * enters)<br/>
 * <br/>
 * Specification Field: outputChutes : List<Chute> // represents the ordered set
 * of output chutes (the index of a given Chute represents the port at which it
 * exits)<br/>
 * <br/>
 * Specification Field: UID : integer // the unique even identifier for this
 * Intersection<br/>
 * 
 * @author Nathaniel Mote
 */

/*
 * Notes:
 * 
 * - I think I have all the the Intersection kinds in the enum, but if I'm
 * missing any, let me know.
 */

public class Intersection
{
   public enum Kind
   {
      INCOMING, // The start point of chutes that are entering the frame on
      // the top
      OUTGOING, // The end point of chutes that are exiting the frame on the
      // bottom
      SPLIT, // An intersection in which a chute is split into multiple chutes
      NULL_TEST, // Represent branching due to testing a value for null
      MERGE, // An intersection where multiple chutes merge into one
      START_WHITE_BALL, // Represents a white (NonNull) ball being dropped
      // into the top of the exit chute
      START_BLACK_BALL, // Represents a black (null) ball being dropped into
      // the top of the exit chute
      START_NO_BALL, // Start a new chute with no ball dropping into it
      END, // Terminate a chute
      RESTART_WHITE_BALL, // Terminate a chute and restart it with a new white
                          // ball
      RESTART_BLACK_BALL, // Terminate a chute and restart it with a new black
                          // ball
      RESTART_NO_BALL, // Terminate a chute and restart it without a ball
      SUBNETWORK, // Represents a method call
      CONNECT, // Simply connects one chute to another, without making any
               // modifications. Can be optimized away after, but I think it
               // will be convenient to have during construction.
   };
   
   private static final boolean CHECK_REP_ENABLED = true;
   
   private final Kind intersectionKind;
   
   // TODO remove warning suppression after JDK is properly annotated
   @SuppressWarnings("nullness") private List</* @Nullable */Chute> inputChutes;
   
   @SuppressWarnings("nullness") private List</* @Nullable */Chute> outputChutes;
   
   private final int UID;
   
   private static int nextUID = 0;
   
   /*
    * Representation Invariant:
    * 
    * Requirements for the number of input/output individual Intersection kinds:
    * 
    * <KIND>(#input, #output)
    * 
    * INCOMING(0, any)
    * 
    * OUTGOING(any, 0)
    * 
    * SPLIT(1, 2)
    * 
    * NULL_TEST(1, 2)
    * 
    * MERGE(2, 1)
    * 
    * START_WHITE_BALL(0, 1)
    * 
    * START_BLACK_BALL(0, 1)
    * 
    * START_NO_BALL(0, 1)
    * 
    * END(1, 0)
    * 
    * RESTART_WHITE_BALL(1, 1)
    * 
    * RESTART_BLACK_BALL(1, 1)
    * 
    * RESTART_NO_BALL(1, 1)
    * 
    * SUBNETWORK(any, any)
    * 
    * CONNECT(1, 1)
    * 
    * This means that the size of inputChutes and outputChutes, respectively,
    * can be no greater than the given number of ports
    */
   
   /**
    * checks that the rep invariant holds
    */
   protected void checkRep()
   {
      if (CHECK_REP_ENABLED)
      {
         // check that there are the proper number of chutes. there may still be
         // fewer chutes than a finished Intersection of this Kind should have,
         // so take that into account.
         switch (intersectionKind)
         {
            case INCOMING:
               ensure(inputChutes.size() == 0);
               break;
            case OUTGOING:
               ensure(outputChutes.size() == 0);
               break;
            case SPLIT:
               ensure(inputChutes.size() <= 1 && outputChutes.size() <= 2);
               break;
            case NULL_TEST:
               ensure(inputChutes.size() <= 1 && outputChutes.size() <= 2);
               break;
            case MERGE:
               ensure(inputChutes.size() <= 2 && outputChutes.size() <= 1);
               break;
            case START_WHITE_BALL:
               ensure(inputChutes.size() == 0 && outputChutes.size() <= 1);
               break;
            case START_BLACK_BALL:
               ensure(inputChutes.size() == 0 && outputChutes.size() <= 1);
               break;
            case START_NO_BALL:
               ensure(inputChutes.size() == 0 && outputChutes.size() <= 1);
               break;
            case END:
               ensure(inputChutes.size() <= 1 && outputChutes.size() == 0);
               break;
            case RESTART_WHITE_BALL:
               ensure(inputChutes.size() <= 1 && outputChutes.size() <= 1);
               break;
            case RESTART_BLACK_BALL:
               ensure(inputChutes.size() <= 1 && outputChutes.size() <= 1);
               break;
            case RESTART_NO_BALL:
               ensure(inputChutes.size() <= 1 && outputChutes.size() <= 1);
               break;
            case SUBNETWORK:
               // no restrictions
               break;
            case CONNECT:
               ensure(inputChutes.size() <= 1 && outputChutes.size() <= 1);
               break;
            
            default:
               throw new RuntimeException(
                     "Add new Intersection Kind to checkRep()");
         }
      }
   }
   
   /**
    * Intended to be a substitute for assert, except I don't want to have to
    * make sure the -ea flag is turned on in order to get these checks.
    */
   private void ensure(boolean value)
   {
      if (!value)
         throw new AssertionError();
   }
   
   /**
    * Creates a new Intersection object of the given kind with empty i/o ports<br/>
    * <br/>
    * Requires: kind != SUBNETWORK<br/>
    * <br/>
    * Subclasses calling this constructor can modify the requires clause by
    * overriding checkIntersectionKind
    * 
    */
   public Intersection(Kind kind)
   {
      
      if (!checkIntersectionKind(kind)) // if this is not a valid Kind for this
                                        // implementation of Intersection
         throw new IllegalArgumentException("Invalid Intersection Kind " + kind
               + " for this implementation");
      
      intersectionKind = kind;
      inputChutes = new ArrayList</* @Nullable */Chute>();
      outputChutes = new ArrayList</* @Nullable */Chute>();
      
      UID = nextUID;
      nextUID += 2;
      
      checkRep();
   }
   
   /**
    * Returns true iff the given kind is a valid intersection kind for this
    * implementation.<br/>
    * <br/>
    * Subclasses should override this so that the call to this class's
    * constructor succeeds.
    */
   protected boolean checkIntersectionKind(Kind kind)
   {
      // this implementation supports every Intersection kind except for
      // SUBNETWORK and NULL_TEST
      return kind != Kind.SUBNETWORK && kind != Kind.NULL_TEST;
   }
   
   /**
    * Returns intersectionKind
    */
   public Kind getIntersectionKind()
   {
      return intersectionKind;
   }
   
   /**
    * Requires: port is a valid port number for this Intersection Modifies: this
    * sets the given chute to this Intersection's input at the given port,
    * replacing the old one, if present
    */
   protected void setInputChute(Chute input, int port)
   {
      nullRemainingElts(inputChutes, port);
      inputChutes.add(port, input);
      checkRep();
   }
   
   /**
    * Requires: port is a valid port number for this Intersection Modifies: this
    * sets the given chute to this Intersection's output at the given port,
    * replacing the old one, if present
    */
   protected void setOutputChute(Chute output, int port)
   {
      nullRemainingElts(outputChutes, port);
      outputChutes.add(port, output);
      checkRep();
   }
   
   /**
    * Returns the chute at the given port, or null if none exists
    */
   public @Nullable Chute getInputChute(int port)
   {
      if (port >= inputChutes.size())
         return null;
      else
         return inputChutes.get(port);
   }
   
   /**
    * Returns the chute at the given port, or null if none exists
    */
   public @Nullable Chute getOutputChute(int port)
   {
      if (port >= outputChutes.size())
         return null;
      else
         return outputChutes.get(port);
   }
   
   /**
    * If minSize is greater than list.size, adds null elements to the end of
    * list until list.size == minSize<br/>
    * <br/>
    * Modifies: list<br/>
    * <br/>
    * Notes: used to make sure that the given list can accommodate a call to add
    * with indices up to minSize
    */
   // TODO Fix name and documentation
   // List is annotated to require non-null elements
   // TODO change after this is corrected
   @SuppressWarnings("nullness") private <E> void nullRemainingElts(
         List</* @Nullable */E> list, int minSize)
   {
      while (list.size() < minSize)
         list.add(null);
   }
   
   /**
    * Returns true iff this is a Subnetwork kind.
    */
   public boolean isSubnetwork()
   {
      return false;
   }
   
   /**
    * Requires: this is of Subnetwork kind Returns this as a Subnetwork
    */
   public Subnetwork asSubnetwork()
   {
      // Is this the right exception to throw?
      throw new IllegalStateException(
            "asSubnetwork called on an Intersection not of Subnetwork kind");
   }
   
   /**
    * Returns true iff this is a NullTest kind
    */
   public boolean isNullTest()
   {
      return false;
   }
   
   /**
    * Requires: this is of NullTest kind Returns this as a NullTest
    */
   public NullTest asNullTest()
   {
      throw new IllegalStateException(
            "asNullTest called on an Intersection not of NullTest kind");
   }
   
   /**
    * Returns UID
    */
   public int getUID()
   {
      return UID;
   }
}
