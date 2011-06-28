package level;

import java.util.ArrayList;
import java.util.List;

import checkers.nullness.quals.*;

/**
 * @author Nathaniel Mote
 * 
 * A mutable ADT representing the intersections between chutes.
 * 
 * It is mutable so that chutes can be added and removed to it.
 * 
 * Uses eternal equality so that it can be used in Collections while maintaining
 * mutability
 * 
 * @specfield type : Intersection.Type // represents which kind of intersection
 * this is
 * 
 * @specfield inputChutes : List<Chute> // represents the ordered set of input
 * chutes (the index of a given Chute represents the port at which it enters)
 * 
 * @specfield outputChutes : List<Chute> // represents the ordered set of output
 * chutes (the index of a given Chute represents the port at which it exits)
 * 
 * @specfield UID : integer // the unique even identifier for this Intersection
 * 
 */

/*
 * Notes:
 * 
 * - I think I have all the the Intersection types in the enum, but if I'm
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
      RE_START_WHITE_BALL, // Terminate a chute and restart it with a new white
                           // ball
      RE_START_BLACK_BALL, // Terminate a chute and restart it with a new black
                           // ball
      RE_START_NO_BALL, // Terminate a chute and restart it without a ball
      SUBNETWORK, // Represents a method call
      CONNECT, // Simply connects one chute to another, without making any
               // modifications.Can be optimized away after, but I think it will
               // be convenient to have during construction.
   };
   
   private final Kind intersectionKind;
   
   // The annotated JDK does not allow null elements in most Collections, but
   // for some reason, ArrayLists are an exception. However, we can't use the
   // List interface, because that will not support NonNull elements
   private ArrayList</* @Nullable */Chute> inputChutes;
   
   private ArrayList</* @Nullable */Chute> outputChutes;
   
   private final int UID;
   
   private static int nextUID = 0;
   
   /*
    * Representation Invariant:
    * 
    * intersectionKind != SUBNETWORK
    */
   
   /**
    * @requires type != SUBNETWORK
    * @effects creates a new Intersection object of the given type with empty
    * i/o ports
    * 
    * Subclasses calling this constructor can modify the requires clause by
    * overriding checkIntersectionType
    * 
    */
   public Intersection(Kind kind)
   {
      
      if (!checkIntersectionKind(kind)) // if this is not a valid Type for this
                                        // implementation of Intersection
         throw new IllegalArgumentException("Invalid Intersection Type " + kind
               + " for this implementation");
      
      intersectionKind = kind;
      inputChutes = new ArrayList</* @Nullable */Chute>();
      outputChutes = new ArrayList</* @Nullable */Chute>();
      
      UID = nextUID;
      nextUID += 2;
      
   }
   
   /**
    * @return true iff the given type is a valid intersection type for this
    * implementation
    */
   protected boolean checkIntersectionKind(Kind kind)
   {
      // this implementation supports every Intersection type except for
      // SUBNETWORK
      return kind != Kind.SUBNETWORK;
   }
   
   /**
    * @return intersectionType
    */
   public Kind getIntersectionKind()
   {
      return intersectionKind;
   }
   
   /**
    * @requires port is a valid port number for this Intersection
    * @modifies this
    * @effects sets the given chute to this Intersection's input at the given
    * port, replacing the old one, if present
    */
   protected void setInputChute(Chute input, int port)
   {
      nullRemainingElts(inputChutes, port);
      inputChutes.add(port, input);
      
   }
   
   /**
    * @requires port is a valid port number for this Intersection
    * @modifies this
    * @effects sets the given chute to this Intersection's output at the given
    * port, replacing the old one, if present
    */
   protected void setOutputChute(Chute output, int port)
   {
      nullRemainingElts(outputChutes, port);
      outputChutes.add(port, output);
   }
   
   public @Nullable Chute getInputChute(int port)
   {
      throw new RuntimeException("Not yet implemented");
   }
   
   public @Nullable Chute getOutputChute(int port)
   {
      throw new RuntimeException("Not yet implemented");
   }
   
   /**
    * @modifes list
    * @effects if minSize is greater than list.size, adds null elements to the
    * end of list until list.size == minSize
    * 
    * Notes: used to make sure that the given list can accommodate a call to add
    * with indices up to minSize
    */
   private <E> void nullRemainingElts(ArrayList</* @Nullable */E> list,
         int minSize)
   {
      while (list.size() < minSize)
         list.add(null);
   }
   
   /**
    * @return true iff this is a Subnetwork type.
    * 
    * Notes: If implemented correctly, this is equivalent to
    * getIntersectionKind() == Kind.SUBNETWORK. Is it still good to include this
    * method?
    */
   public boolean isSubnetwork()
   {
      return false;
   }
   
   /**
    * @requires this is of Subnetwork type
    * @return this as a Subnetwork
    */
   public Subnetwork asSubnetwork()
   {
      // Is this the right exception to throw?
      throw new IllegalStateException(
            "asSubnetwork called on an Intersection not of Subnetwork type");
   }
   
   /**
    * @return UID
    */
   public int getUID()
   {
      return UID;
   }
}
