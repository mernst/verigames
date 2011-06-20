/**
 * @author Nathaniel Mote
 * 
 * A mutable ADT representing the intersections between chutes.
 * 
 * It is mutable so that chutes can be added and removed to it.
 * 
 * equals and hashCode are not overridden. Because Intersection objects will be
 * used in Sets, this means that their mutability will not cause problems.
 * 
 * @specfield type : Intersection.IntersectionType // represents which kind of
 * intersection this is
 * 
 * @specfield input : List<Chute> // represents the ordered set of input chutes
 * (the index of a given Chute represents the port at which it enters)
 * 
 * @specfield output : List<Chute> // represents the ordered set of output
 * chutes (the index of a given Chute represents the port at which it exits)
 * 
 */

public class Intersection
{
	// enum names use draft terminology -- comments welcome
	public enum Type
	{
		INCOMING, // The start point of chutes that are entering the frame on
		// the top
		OUTGOING, // The end point of chutes that are exiting the frame on the
		// bottom
		SPLIT, // An intersection in which a chute is split into multiple chutes
		NULL_TEST, //
		MERGE, // An intersection where multiple chutes merge into one
		START_WHITE_BALL, // Represents a white (NonNull) ball being dropped
		// into the top of the exit chute
		START_BLACK_BALL, // Represents a black (null) ball being dropped into
		// the top of the exit chute
		START_NO_BALL, // Start a new chute with no ball dropping into it
		END, //	Terminate a chute
		RE_START_WHITE_BALL, // Terminate a chute and restart it with a new white ball
		RE_START_BLACK_BALL, // Terminate a chute and restart it with a new black ball
		RE_START_NO_BALL, // Terminate a chute and restart it without a ball
		SUBNETWORK, // Represents a method call,
		
	};
	
	// Should the enums perhaps include instance fields to specify how many
	// input and output chutes they can have?
	
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
	 * @effects creates a new Intersection object of type SUBNETWORK, with the specific subnetwork defined by the argument
	 * 
	 */
	public Intersection(String methodName /* String is a place-holder for whatever we decide to use to refer to methods */)
	{
		throw new RuntimeException("Not yet implemented");
	}
	
	/**
	 * 
	 */
	// public setChute()
}
