/**
 * @author: Nathaniel Mote
 * 
 * A mutable structure representing chute segments.
 * 
 * @specfield start : Intersection // The starting point of this Chute
 * @specfield end : Intersection // The ending point of this Chute
 * 
 * @specfield pinch : boolean // true iff there is a pinch-point in this chute segment
 * 
 * @specfield narrow : boolean // true iff the chute is currently narrow
 * 
 * Except in corner cases, pinch --> narrow
 * 
 */

public class Chute
{
	
	private Intersection start;
	private Intersection end;
	private boolean pinch;
	private boolean narrow;
	
	public Chute()
	{
		throw new RuntimeException("Not yet implemented");
	}
	
}
