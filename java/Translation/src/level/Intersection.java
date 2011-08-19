package level;

import java.util.TreeMap;

/**
 * An intersection between chutes. Mutable until deactivated<br/>
 * <br/>
 * Uses eternal equality so that it can be used in {@code Collection}s while
 * maintaining mutability<br/>
 * <br/>
 * Specification Field: {@code kind} : {@link Intersection.Kind}
 * // represents which kind of {@code Intersection} {@code this} is<br/>
 * <br/>
 * Specification Field: Layout Coordinate : (x: integer, y:integer) // The
 * coordinates at which {@code this} will be located when its containing {@link
 * Board} is laid out to be played.<br/>
 * <br/>
 * Specification Field: {@code UID} : integer // the unique identifier for this
 * {@code Intersection}
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
   /**
    * Specifies different kinds of {@code Intersection}s. Different kinds of
    * {@code Intersection}s are used for different purposes in a
    * {@link level.Board Board}.
    */
   public static enum Kind
   {
      /** The start point of chutes that enter the board on the top */
      INCOMING,
      /** The end point of chutes that exit the board on the bottom */
      OUTGOING,
      /** An intersection in which a chute is split into two chutes */
      SPLIT,
      /** An intersection where two chutes merge into one */
      MERGE,
      /**
       * Simply connects one chute to another. Can be optimized away after, but
       * I think it will be convenient to have during construction.
       */
      CONNECT,
      /** Represents a split due to testing for null */
      NULL_TEST,
      /**
       * Represents a white (not null) ball being dropped into the top of the
       * exit chute
       */
      START_WHITE_BALL,
      /**
       * Represents a black (null) ball being dropped into the top of the exit
       * chute
       */
      START_BLACK_BALL,
      /** Represents a chute with no ball dropping into it */
      START_NO_BALL,
      /** Terminate a chute */
      END,
      /** Represents a method call */
      SUBNETWORK,
   };
   
   private static final boolean CHECK_REP_ENABLED = true;
   
   private final Kind intersectionKind;

   private int x;
   private int y;
   
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
   @Override protected void checkRep()
   {
      super.checkRep();
      
      if (!CHECK_REP_ENABLED)
         return;
      
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
          * Ensures that both the highest port number plus one and the number of
          * used input/output ports can be no greater than the value returned by
          * getNumberOfInputPorts() and getNumberOfOutputPorts().
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
   
   /**
    * Returns the number of input ports for a completed {@code Intersection} of
    * this {@code Kind}, or {@code -1} if there is no restriction<br/>
    * <br/>
    * When deactivated, an {@code Intersection} must have all of its ports
    * filled.
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
    * Returns the number of output ports for a completed {@code Intersection} of
    * this {@code Kind}, or {@code -1} if there is no restriction<br/>
    * <br/>
    * When deactivated, an {@code Intersection} must have all of its ports
    * filled.
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
   private static void ensure(boolean value)
   {
      if (!value)
         throw new AssertionError();
   }
   
   /**
    * Returns an {@code Intersection} of the {@link Intersection.Kind Kind}
    * {@code kind}<br/>
    * <br/>
    * Requires: {@code kind !=} {@link Kind#SUBNETWORK SUBNETWORK} (use
    * {@link #subnetworkFactory(java.lang.String) subnetworkFactory})
    * 
    * @param kind
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
   
   /**
    * Returns a {@link Subnetwork} representing a method with {@code methodName}
    * 
    * @param methodName
    */
   public static Subnetwork subnetworkFactory(String methodName)
   {
      return new Subnetwork(methodName);
   }
   
   /**
    * Creates a new {@code Intersection} of the given {@code Kind} with empty
    * input and output ports<br/>
    * <br/>
    * Requires:<br/>
    * - {@code checkIntersectionKind(kind)}<br/>
    * <br/>
    * Subclasses calling this constructor override
    * {@link #checkIntersectionKind(Kind)} to change the restrictions on what
    * {@link Intersection.Kind Kind}s can be used.
    * 
    * @param kind
    * The kind of {@code Intersection} to create
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
    * Returns true iff {@code kind} is valid for this implementation of
    * {@code Intersection}.<br/>
    * <br/>
    * This implementation supports all {@link Intersection.Kind Kind}s except
    * {@link Kind#SUBNETWORK SUBNETWORK} and {@link Kind#NULL_TEST NULL_TEST}
    * 
    * @param kind
    */
   protected boolean checkIntersectionKind(Kind kind)
   {
      // this implementation supports every Intersection kind except for
      // SUBNETWORK and NULL_TEST
      return kind != Kind.SUBNETWORK && kind != Kind.NULL_TEST;
   }
   
   /**
    * Returns {@code intersectionKind}
    */
   public Kind getIntersectionKind()
   {
      return intersectionKind;
   }

   public void setX(int x)
   {
      this.x = x;
   }

   public int getX()
   {
      return x;
   }

   public void setY(int y)
   {
      this.y = y;
   }

   public int getY()
   {
      return y;
   }
   
   /**
    * Returns {@code true} iff {@code this} is a {@link Subnetwork}.
    */
   public boolean isSubnetwork()
   {
      return false;
   }
   
   /**
    * Returns {@code this} as a {@link Subnetwork}<br/>
    * <br/>
    * Requires: {@link #isSubnetwork()}
    */
   public Subnetwork asSubnetwork()
   {
      // Is this the right exception to throw?
      throw new IllegalStateException(
            "asSubnetwork called on an Intersection not of Subnetwork kind");
   }
   
   /**
    * Returns {@code true} iff this is a {@link NullTest}
    */
   public boolean isNullTest()
   {
      return false;
   }
   
   /**
    * Returns {@code this} as a {@link NullTest}<br/>
    * <br/>
    * Requires: {@link #isSubnetwork()}
    */
   public NullTest asNullTest()
   {
      throw new IllegalStateException(
            "asNullTest called on an Intersection not of NullTest kind");
   }
   
   /**
    * Returns {@code UID}
    */
   public int getUID()
   {
      return UID;
   }
   
}
