package level;

import java.util.TreeMap;


/**
 * A mutable (until deactivated) ADT representing an intersection between
 * chutes.<br/>
 * <br/>
 * It is mutable, until deactivated, so that chutes can be added and removed to
 * it.<br/>
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
 * Specification Field: UID : integer // the unique identifier for this
 * Intersection<br/>
 * <br/>
 * Specification Field: active : boolean // true iff this can be part of a
 * structure that is still under construction. once active is set to false, this
 * becomes immutable.
 * 
 * @author Nathaniel Mote
 */

/*
 * Notes:
 * 
 * - I think I have all the the Intersection kinds in the enum, but if I'm
 * missing any, let me know.
 */

public class Intersection extends graph.Node<Chute>
{
   public static enum Kind
   {
      INCOMING, // The start point of chutes that are entering the frame on
      // the top
      OUTGOING, // The end point of chutes that are exiting the frame on the
      // bottom
      SPLIT, // An intersection in which a chute is split into multiple chutes
      MERGE, // An intersection where multiple chutes merge into one
      CONNECT, // Simply connects one chute to another, without making any
      // modifications. Can be optimized away after, but I think it
      // will be convenient to have during construction.
      NULL_TEST, // Represent branching due to testing a value for null
      START_WHITE_BALL, // Represents a white (NonNull) ball being dropped
      // into the top of the exit chute
      START_BLACK_BALL, // Represents a black (null) ball being dropped into
      // the top of the exit chute
      START_NO_BALL, // Start a new chute with no ball dropping into it
      END, // Terminate a chute
      SUBNETWORK, // Represents a method call
   };
   
   private static final boolean CHECK_REP_ENABLED = true;
   
   private final Kind intersectionKind;
   
   private final int UID;
   
   private static int nextUID = 0;
   
   /*
    * Representation Invariant:
    * 
    * When active, both the highest port number plus one and the number of used
    * input/output ports can be no greater than the value returned by
    * getNumberOfInputPorts() and getNumberOfOutputPorts().
    * 
    * When inactive, both the highest port number plus one and the number of
    * used input/output ports must be exactly equal to the value returned by
    * getNumberOf____Ports(),
    */
   
   /**
    * checks that the rep invariant holds
    */
   // TODO fix checkRep
   protected void checkRep()
   {
      if (CHECK_REP_ENABLED)
      {
         // The total number of ports that this Kind of Intersection can have
         int numRequiredInPorts = getNumberOfInputPorts();
         int numRequiredOutPorts = getNumberOfOutputPorts();
         
         TreeMap<Integer, Chute> inputChutes = getInputs();
         TreeMap<Integer, Chute> outputChutes = getOutputs();
         
         int usedInPorts = inputChutes.size();
         int usedOutPorts = outputChutes.size();
         
         // the size of the ports list, based on the highest index
         int maxInPorts = inputChutes.isEmpty() ? 0 : inputChutes.lastKey() + 1;
         int maxOutPorts = outputChutes.isEmpty() ? 0 : outputChutes.lastKey() + 1;
         
         if (isActive())
         {
            /*
             * Ensures that both the highest port number plus one and the number
             * of used input/output ports can be no greater than the value
             * returned by getNumberOfInputPorts() and getNumberOfOutputPorts().
             */
            
            
            if (numRequiredInPorts != -1)
            {
               ensure(usedInPorts <= numRequiredInPorts);
               ensure(maxInPorts <= numRequiredInPorts);
            }
            
            if (numRequiredOutPorts != -1)
            {
               ensure(usedOutPorts <= numRequiredOutPorts);
               ensure(maxOutPorts <= numRequiredOutPorts);
            }
         }
         else
         {
            // Ensures that the all ports are filled
            
            if (numRequiredInPorts != -1)
            {
               ensure(usedInPorts == numRequiredInPorts);
               ensure(maxInPorts == numRequiredInPorts);
            }
            
            if (numRequiredOutPorts != -1)
            {
               ensure(usedOutPorts == numRequiredOutPorts);
               ensure(maxOutPorts == numRequiredOutPorts);
            }
         }
      }
   }
   
   /**
    * Returns the number of input ports for an Intersection of this Kind, or -1 if there is no limit<br/>
    * <br/>
    * When construction is completed, an Intersection must have all of its ports filled.
    */
   private int getNumberOfInputPorts()
   {
      switch (intersectionKind)
      {
         case INCOMING:
            return 0;
         case OUTGOING:
            return -1;
         case SPLIT:
            return 1;
         case NULL_TEST:
            return 1;
         case MERGE:
            return 2;
         case START_WHITE_BALL:
            return 0;
         case START_BLACK_BALL:
            return 0;
         case START_NO_BALL:
            return 0;
         case END:
            return 1;
         case SUBNETWORK:
            return -1;
         case CONNECT:
            return 1;
            
         default:
            throw new RuntimeException(
                  "Add new Intersection Kind to switch statement");
      }
   }
   
   /**
    * Returns the number of output ports for an Intersection of this Kind, or -1 if there is no limit<br/>
    * <br/>
    * When construction is completed, an Intersection must have all of its ports filled.
    */
   private int getNumberOfOutputPorts()
   {
      switch (intersectionKind)
      {
         case INCOMING:
            return -1;
         case OUTGOING:
            return 0;
         case SPLIT:
            return 2;
         case NULL_TEST:
            return 2;
         case MERGE:
            return 1;
         case START_WHITE_BALL:
            return 1;
         case START_BLACK_BALL:
            return 1;
         case START_NO_BALL:
            return 1;
         case END:
            return 0;
         case SUBNETWORK:
            return -1;
         case CONNECT:
            return 1;
            
         default:
            throw new RuntimeException(
                  "Add new Intersection Kind to switch statement");
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
    * Returns an Intersection of the given Kind<br/>
    * <br/>
    * Requires: kind != SUBNETWORK (use subnetworkFactory)
    * 
    * @param kind
    * The kind of Intersection to return
    * 
    */
   public static Intersection factory(Kind kind)
   {
      if (kind == Kind.SUBNETWORK)
         throw new IllegalArgumentException(
               "intersectionFactory passed Kind.SUBNETWORK. Use subnetworkFactory instead.");
      else if (kind == Kind.NULL_TEST)
         return new NullTest();
      else
         return new Intersection(kind);
   }
   
   public static Subnetwork subnetworkFactory(String methodName)
   {
      return new Subnetwork(methodName);
   }
   
   /**
    * Creates a new Intersection object of the given kind with empty i/o ports<br/>
    * <br/>
    * Requires:<br/>
    * kind != NULL_TEST;<br/>
    * kind != SUBNETWORK<br/>
    * <br/>
    * Subclasses calling this constructor can modify the requires clause by
    * overriding checkIntersectionKind
    * 
    * @param kind
    * The kind of Intersection to create
    * 
    */
   protected Intersection(Kind kind)
   {
      
      if (!checkIntersectionKind(kind)) // if this is not a valid Kind for this
                                        // implementation of Intersection
         throw new IllegalArgumentException("Invalid Intersection Kind " + kind
               + " for this implementation");
      
      intersectionKind = kind;
      
      UID = nextUID;
      nextUID += 1;
      
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
