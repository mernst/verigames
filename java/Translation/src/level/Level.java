package level;

import java.io.PrintStream;
import java.util.Map;
import java.util.Set;
import javax.lang.model.element.Name;

/**
 * @author: Nathaniel Mote
 * 
 * A mutable data structure that represents a complete level
 * 
 * @specfield: contiguousEdgeMap: Map<Chute, Set<Chute>> // maps edges to a set
 * of their contiguous edges
 * 
 * @specfield: boardSet: Set<Board> // represents the set of all boards in this
 * level
 * 
 * @specfield: nameMap: Map<Name, Board> // maps the name of a method to its
 * board
 * 
 * 
 */

/*
 * Notes:
 * 
 * - The contiguous edge map is really representing a set of sets. The idea is
 * that some chutes are necessarily of the same type. This could easily be
 * represented as a Set<Set<Chute>>, and it would be more natural that way. The
 * only concern is that this turns a constant-time lookup to linear time in the
 * number of Set<Chute>'s. However, this number should be so small as to be
 * negligible.
 * 
 * More abstractly: Let R be an equivalence relation on the set of all Chutes
 * such that aRb <--> a and b necessarily have the same width.
 * 
 * The contiguousEdgeMap is, then, for all c in the set of Chutes, a mapping
 * from c to [c], where [c] is the R-equivalence class of c.
 * 
 * I'm not sure if it will be helpful to generalize it like that, but it came to
 * mind.
 */

public class Level
{
   
   /**
    * @effects creates a new Level object with an empty contiguousEdgeMap,
    * boardSet, and nameMap
    */
   public Level()
   {
      throw new RuntimeException("Not yet implemented");
   }
   
   /**
    * @modifies this
    * @effects makes it so that the given chutes are equivalent under the
    * relation R defined above. In other words, for all a, b in chutes (the
    * argument to this method), aRb
    */
   public void makeContiguous(Set<Chute> chutes)
   {
      throw new RuntimeException("Not yet implemented");
   }
   
   /**
    * @requires b is not in boardSet, name is not in nameMap.keySet()
    * @modifies this
    * @effects adds b to boardSet, and adds the mapping from name to b to
    * nameMap
    */
   public void addBoard(Name name, Board b)
   {
      throw new RuntimeException("Not yet implemented");
   }
   
   /**
    * @return boardSet
    */
   public Set<Board> boardSet()
   {
      throw new RuntimeException("Not yet implemented");
   }
   
   /**
    * @return the Board that name maps to in nameMap, or null if it maps to
    * nothing
    */
   public/* @Nullable */Board getBoard(Name name)
   {
      throw new RuntimeException("Not yet implemented");
   }
   
   /**
    * @requires out is open and ready to be written to
    * @modifies out
    * @effects prints the text of the XML representation of this Level to the
    * given PrintStream
    * @return true iff no detectable problems occur
    * 
    * My Java file IO is a little rusty, so let me know if I should be using
    * something other than a PrintStream
    */
   public boolean outputXML(PrintStream out)
   {
      throw new RuntimeException("Not yet implemented");
   }
}
