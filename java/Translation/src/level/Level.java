package level;

import java.io.PrintStream;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;

/**
 * @author: Nathaniel Mote
 * 
 * A mutable data structure that represents a complete level
 * 
 * @specfield: linkedEdges: Set<Set<Chute>> // maps edges to their set of
 * 
 * @specfield: boardSet: Set<Board> // represents the set of all boards in this
 * level
 * 
 * @specfield: nameMap: Map<String, Board> // maps the name of a method to its
 * board
 * 
 * 
 */

/*
 * Notes:
 * 
 * - The linked edge map is really representing a set of sets. The idea is that
 * some chutes are necessarily of the same type. This could easily be
 * represented as a Set<Set<Chute>>, and it would be more natural that way. The
 * only concern is that this turns a constant-time lookup to linear time in the
 * number of Set<Chute>'s. However, this number should be so small as to be
 * negligible.
 * 
 * More abstractly: Let R be an equivalence relation on the set of all Chutes
 * such that aRb <--> a and b necessarily have the same width.
 * 
 * The linkedEdgeMap is, then, for all c in the set of Chutes, a mapping from c
 * to [c], where [c] is the R-equivalence class of c.
 * 
 * I'm not sure if it will be helpful to generalize it like that, but it came to
 * mind.
 * 
 * - I've decided (tentatively) to represent it as a Set<Set<Chute>>. It still
 * wouldn't be too much trouble to switch, though.
 */

public class Level
{
   
   private Set<Set<Chute>> linkedEdges;
   
   // TODO change String, if necessary, to whatever we end up using
   private Map<String, Board> nameMap;
   
   /**
    * @effects creates a new Level object with an empty linkedEdgeMap, boardSet,
    * and nameMap
    */
   public Level()
   {
      linkedEdges = new HashSet<Set<Chute>>();
      nameMap = new HashMap<String, Board>();
   }
   
   /**
    * @modifies this
    * @effects makes it so that the given chutes are equivalent under the
    * relation R defined above. In other words, for all a, b in chutes (the
    * argument to this method), aRb
    */
   public void makeLinked(Set<Chute> toLink)
   {
      // This set contains all of the sets in linkedEdges that contain elements
      // in toLink
      Set<Set<Chute>> containsToLink = new HashSet<Set<Chute>>();
      
      for (Set<Chute> set : linkedEdges)
      {
         for (Chute c : toLink)
         {
            // if a set in linkedEdges contains any element in toLink, it should
            // be added to containsToLink
            if (set.contains(c))
               containsToLink.add(set);
         }
      }
      
      // All of the sets in containsToLink and toLink should be combined into
      // one, and the other chutes should be removed from linkedEdges:
      linkedEdges.removeAll(containsToLink);
      
      // TODO finish implementation
      
      throw new RuntimeException("Not yet implemented");
   }
   
   /**
    * @requires b is not in boardSet, name is not in nameMap.keySet()
    * @modifies this
    * @effects adds b to boardSet, and adds the mapping from name to b to
    * nameMap
    */
   public void addBoard(String name, Board b)
   {
      nameMap.put(name, b);
   }
   
   /**
    * @return a shallow copy of boardSet
    */
   public Set<Board> boardSet()
   {
      return new HashSet<Board>(nameMap.values());
   }
   
   /**
    * @return the Board that name maps to in nameMap, or null if it maps to
    * nothing
    */
   public/* @Nullable */Board getBoard(String name)
   {
      return nameMap.get(name);
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
      out.println("<level>");
      outputLinkedEdges(out);
      //outputBoardMap(out);
      out.println("<level/>");
      throw new RuntimeException("Not yet implemented");
   }
   
   /**
    * @modifies out
    * @effects prints the linked edge section of the xml to out, indented by one
    * space
    */
   private void outputLinkedEdges(PrintStream out)
   {
      out.println(" <linked-edges>");
      for (Set<Chute> set : linkedEdges)
      {
         out.println("  <set>");
         for (Chute c : set)
         {
            out.println("   <value id=\"" + c.getUID() + "\"/>");
         }
         out.println(" </set>");
      }
      out.println(" </linked-edges>");
   }
}
