package level;

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
 * @specfield input : List<Chute> // represents the ordered set of input chutes
 * (the index of a given Chute represents the port at which it enters)
 * 
 * @specfield output : List<Chute> // represents the ordered set of output
 * chutes (the index of a given Chute represents the port at which it exits)
 * 
 * @specfield UID : integer // the unique even identifier for this Intersection
 * 
 */

/*
 * Notes:
 * 
 * - Should Intersection be an interface, with different implementations for
 * different types of intersections? This may lead to too much bloat, but the
 * SUBNETWORK type requires additional information. We could just have a field
 * that isn't used unless it's a SUBNETWORK type, as this specification suggests
 * 
 * - Should the enums perhaps include instance fields to specify how many input
 * and output chutes they can have?
 * 
 * - Should there be enums for restarting chutes, even though the same effect
 * can be accomplished through an end node then a start node? In other words, is
 * the added bloat worth the convenience?
 * 
 * - I think I have all the the Intersection types in the enum, but if I'm
 * missing any, let me know.
 */

public class Intersection
{
   public enum Type
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
   
   private final Type intersectionType;
   
   /**
    * @effects creates a new Intersection object of the given type with empty
    * i/o ports
    */
   public Intersection(Type type)
   {
      throw new RuntimeException("Not yet implemented");
   }
   
   /**
    * @requires methodName stands in for a valid subnetwork
    * @effects creates a new Intersection object of type SUBNETWORK, with the
    * specific subnetwork defined by the argument
    * 
    */
   public Intersection(String methodName /*
                                          * String is a place-holder for
                                          * whatever we decide to use to refer
                                          * to methods
                                          */)
   {
      throw new RuntimeException("Not yet implemented");
   }
   
   /**
    * @requires port is a valid port number for this Intersection
    * @modifies this
    * @effects sets the given chute to this Intersection's input at the given
    * port, replacing the old one, if present
    */
   protected void setInputChute(Chute input, int port)
   {
      throw new RuntimeException("Not yet implemented");
   }
   
   /**
    * @requires port is a valid port number for this Intersection
    * @modifies this
    * @effects sets the given chute to this Intersection's output at the given
    * port, replacing the old one, if present
    */
   protected void setOutputChute(Chute output, int port)
   {
      throw new RuntimeException("Not yet implemented");
   }
}
