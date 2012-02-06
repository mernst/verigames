package verigames.level;

import static verigames.utilities.Misc.ensure;

import java.util.TreeMap;

/**
 * An intersection between {@link Chute}s. Mutable until construction is
 * finished.
 * <p>
 * Uses eternal equality so that it can be used in {@code Collection}s while
 * maintaining mutability.
 * <p>
 * Most {@code Intersection}s simply serve to connect different {@code Chute}s,
 * indicating a relationship between the types that the {@code Chute}s
 * represent. However, some special {@code Intersection}s exist:
 * <ul>
 * <li>
 * INCOMING: An INCOMING node is at the top of every {@link Board}. It serves as
 * the starting point for the topmost {@code Chute}s in the {@code Board} that
 * represent the types for fields and method parameters.
 * </li>
 * <li>
 * OUTGOING: An OUTGOING node is at the bottom of every {@code Board}. It serves
 * as the ending point for the bottommost {@code Chute}s in the {@code Board}
 * that represent the types for fields and return values.
 * </li>
 * <li>
 * SUBNETWORK: A SUBNETWORK node represents a method call. It is essentially a
 * {@code Board} embedded within another {@code Board}.
 * </li>
 * <li>
 * NULL_TEST: A NULL_TEST ndoe represents an if statement conditional on the
 * nullness type of a variable. On one side of the branch, the variable is
 * considered Nullable, and on the other, it is considered NonNull.
 * </li>
 * START_XXX_BALL and END: These are used to start and end chutes for the types
 * of local variables. Local variables don't persist outside of the methods in
 * which they are contained, so their chutes do not connect to the INCOMING and
 * OUTGOING nodes. START_NO_BALL is used when a type exists, but nothing about
 * it is known.
 * </li>
 * </ul>
 * <p>
 * Specification Field: {@code kind} : {@link Intersection.Kind}
 * // represents which kind of {@code Intersection} {@code this} is.
 * <p>
 * Specification Field: Layout Coordinate : (x: real, y:real) // The coordinates
 * at which {@code this} will be located when its containing {@link Board} is
 * laid out to be played.
 * <p>
 * Specification Field: {@code UID} : integer // the unique identifier for this
 * {@code Intersection}.
 * 
 * @author Nathaniel Mote
 */

public class Intersection extends verigames.graph.Node<Chute>
{
  /**
   * Specifies different kinds of {@code Intersection}s. Different kinds of
   * {@code Intersection}s are used for different purposes in a
   * {@link verigames.level.Board Board}.
   */
  public static enum Kind
  {
    /** The start point of chutes that enter the board on the top */
    INCOMING(0, -1),
    /** The end point of chutes that exit the board on the bottom */
    OUTGOING(-1, 0),
    /** An intersection in which a chute is split into two chutes */
    SPLIT(1, 2),
    /** An intersection where two chutes merge into one */
    MERGE(2, 1),
    /**
     * Simply connects one chute to another. Can be optimized away after, but
     * I think it will be convenient to have during construction.
     */
    CONNECT(1, 1),
    /** Represents a split due to testing for null */
    NULL_TEST(1, 2),
    /**
     * Represents a white (not null) ball being dropped into the top a chute.
     */
    START_WHITE_BALL(0, 1),
    /**
     * Represents a black (null) ball being dropped into the top of a chute.
     */
    START_BLACK_BALL(0, 1),
    /** Represents a chute with no ball dropping into it */
    START_NO_BALL(0, 1),
    /** Terminate a chute */
    END(1, 0),
    /** Represents a method call */
    SUBNETWORK(-1, -1);
    
    /**
     * The number of input ports that an {@link Intersection} of this {@code
     * Kind} must have. {@code -1} if there is no restriction.
     */
    private final int numInputPorts;
    /**
     * The number of output ports that an {@link Intersection} of this {@code
     * Kind} must have. {@code -1} if there is no restriction.
     */
    private final int numOutputPorts;
    
    /**
     * Constructs a new {@code Kind} enum object.
     *
     * @param numInputPorts
     * The number of input ports that an {@link Intersection} of this {@code
     * Kind} must have. {@code -1} if there is no restriction.
     *
     * @param numOutputPorts
     * The number of output ports that an {@link Intersection} of this {@code
     * Kind} must have. {@code -1} if there is no restriction.
     */
    private Kind(int numInputPorts, int numOutputPorts)
    {
      this.numInputPorts = numInputPorts;
      this.numOutputPorts = numOutputPorts;
    }
    
    /**
     * Returns the number of input ports that an {@link Intersection} of this
     * {@code Kind} must have, or {@code -1} if there is no restriction.
     */
    public int getNumberOfInputPorts()
    {
      return this.numInputPorts;
    }
    
    /**
     * Returns the number of output ports that an {@link Intersection} of this
     * {@code Kind} must have, or {@code -1} if there is no restriction.
     */
    public int getNumberOfOutputPorts()
    {
      return this.numOutputPorts;
    }
  };
  
  private static final boolean CHECK_REP_ENABLED = verigames.utilities.Misc.CHECK_REP_ENABLED;
  
  private final Kind intersectionKind;
  
  private double x = -1d;
  private double y = -1d;
  
  private final int UID;
  
  private static int nextUID = 0;
  
  /*
   * Representation Invariant:
   * 
   * When underConstruction, both the highest port number plus one and the number of used
   * input/output ports can be no greater than the value returned by
   * getNumberOfInputPorts() and getNumberOfOutputPorts().
   * 
   * When constructed, both the highest port number plus one and the number of
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
    int numRequiredInPorts = intersectionKind.getNumberOfInputPorts();
    int numRequiredOutPorts = intersectionKind.getNumberOfOutputPorts();
    
    TreeMap<Integer, Chute> inputChutes = getInputs();
    TreeMap<Integer, Chute> outputChutes = getOutputs();
    
    int usedInPorts = inputChutes.size();
    int usedOutPorts = outputChutes.size();
    
    // the size of the ports list, based on the highest index
    int maxInPorts = inputChutes.isEmpty() ? 0 : inputChutes.lastKey() + 1;
    int maxOutPorts = outputChutes.isEmpty() ? 0 : outputChutes.lastKey() + 1;
    
    if (underConstruction())
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
    
    if (!checkIntersectionKind(kind)) // if kind is not a valid Kind for this
      // implementation of Intersection
      throw new IllegalArgumentException("Invalid Intersection Kind " + kind
          + " for this implementation");
    
    this.intersectionKind = kind;
    
    this.UID = Intersection.nextUID;
    Intersection.nextUID++;
    
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
  protected boolean checkIntersectionKind(Kind kind) /*@Raw*/
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
  
  /**
   * Sets the x coordinate that {@code this} is to appear at to {@code x}.
   *
   * @param x
   * Must be nonnegative
   */
  public void setX(double x)
  {
    if (x < 0)
      throw new IllegalArgumentException("x value of " + x + " illegal -- must be nonnegative");
    this.x = x;
  }
  
  /**
   * Returns the x coordinate that {@code this} is to appear at, or -1 if none
   * has been set.
   */
  public double getX()
  {
    return x;
  }
  
  /**
   * Sets the y coordinate that {@code this} is to appear at to {@code y}.
   *
   * @param y
   * Must be nonnegative
   */
  public void setY(double y)
  {
    if (y < 0)
      throw new IllegalArgumentException("y value of " + y + " illegal -- must be nonnegative");
    this.y = y;
  }
  
  /**
   * Returns the y coordinate that {@code this} is to appear at, or -1 if none
   * has been set.
   */
  public double getY()
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
  
  @Override
  protected String shallowToString()
  {
    return getIntersectionKind().toString() + "#" + getUID();
  }
  
  /** Every intersection can be assigned to a board.
   * Null until it is assigned to a board.
   */
  private /*@LazyNonNull*/ Board board;
  
  /**
   * Sets the {@link Board} that {@code this} is in. Cannot be changed once
   * construction is finished.
   *
   * @see verigames.graph.Node#underConstruction()
   * @see verigames.graph.Node#finishConstruction()
   */
  public void setBoard(Board p) {
    if (!this.underConstruction())
      throw new IllegalStateException(
          "Mutation attempted on a constructed Intersection");
    board = p;
  }
  
  public /*@Nullable*/ Board getBoard() {
    return board; 
  }
}
