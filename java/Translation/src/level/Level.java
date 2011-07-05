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
   
   /*
    * Representation Invariant:
    * 
    * No chute can be contained in more than one set in linkedEdges
    * 
    * No set in linkedEdges may be empty
    * 
    * No set in linkedEdges may have size 1 (the fact that a chute is linked to
    * itself need not be represented)
    * 
    * All chutes contained in sets contained in linkedEdges must also be
    * contained contained by some Board in nameMap.values()
    */
   
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
    * @requires every Chute in toLink must be contained in a Board in nameMap
    * @modifies this
    * @effects makes it so that the given chutes are equivalent under the
    * relation R defined above. In other words, for all a, b in chutes (the
    * argument to this method), aRb
    * 
    * runs in O(m*n) time, where m is linkedEdges.size() and n is toLink.size()
    */
   public void makeLinked(Set<Chute> toLink)
   {
      // This set is to contain all of the sets in linkedEdges that contain
      // elements in toLink
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
      
      // All of the elements in the sets in containsToLink and toLink should be
      // put into a single set. This is accomplished by creating a new set with
      // all the elements in it, and removing the old ones from linkedEdges
      
      Set<Chute> newEquivClass = new HashSet<Chute>();
      
      // take all of the elements in all of the chutes that contain elements
      // that are supposed to be linked and add them to the new set
      for (Set<Chute> s : containsToLink)
         newEquivClass.addAll(s);
      
      newEquivClass.addAll(toLink);
      
      linkedEdges.removeAll(containsToLink);
      
      linkedEdges.add(newEquivClass);
   }
   
   /**
    * @return true iff all of the chutes in the given set are linked
    */
   public boolean areLinked(Set<Chute> chutes)
   {
      // A single chute is always linked to itself
      if (chutes.size() == 1)
         return true;
      
      for (Set<Chute> s : linkedEdges)
      {
         if (s.containsAll(chutes))
            return true;
      }
      return false;
   }
   
   /**
    * TODO add clause about how the board must be well-formed and complete.
    * 
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
    * 
    * My Java file IO is a little rusty, so let me know if I should be using
    * something other than a PrintStream
    */
   public void outputXML(PrintStream out)
   {
      out.println("<?xml version=\"1.0\"?>");
      out.println("<!DOCTYPE level SYSTEM \"level.dtd\">");
      out.println("<level>");
      outputLinkedEdges(out);
      outputBoardsMap(out);
      out.println("</level>");
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
   
   /**
    * @modifies out
    * @effects prints the board map section of the xml to out, indented by one
    * space
    */
   // TODO add "editable" attribute to edge output (involves editing DTD)
   private void outputBoardsMap(PrintStream out)
   {
      out.println(" <boards-map>");
      for (String name : nameMap.keySet())
      {
         Board board = nameMap.get(name);
         out.println("  <board name=\"" + name + "\">");
         
         for (Intersection node : board.getNodes())
         {
            out.println("   <node kind=\"" + node.getIntersectionKind()
                  + "\" id=\"" + node.getUID() + "\">");
            out.println("    <input>");
            
            Chute input = node.getInputChute(0);
            for (int i = 0; input != null; input = node.getInputChute(++i))
               out.println("     <port num=\"" + i + "\" edge=\""
                     + input.getUID() + "\"/>");
            
            out.println("    </input>");
            out.println("    <output>");
            
            Chute output = node.getInputChute(0);
            for (int i = 0; output != null; output = node.getOutputChute(++i))
               out.println("     <port num=\"" + i + "\" edge=\""
                     + output.getUID() + "\"/>");
            
            out.println("    </output>");
            out.println("   </node>");
         }
         
         for (Chute edge : board.getEdges())
         {
            out.println("   <edge var=\"" + edge.getName() + "\" pinch=\""
                  + edge.isPinched() + "\" width=\""
                  + (edge.isNarrow() ? "narrow" : "wide") + "\" id=\""
                  + edge.getUID() + "\">");
            
            out.println("    <from>");
            // TODO do something about this nullness warning
            out.println("     <noderef id=\"" + edge.getStart().getUID()
                  + "\" port=\"" + edge.getStartPort() + "\"/>");
            out.println("    </from>");
            out.println("    <to>");
            // TODO do something about this nullness warning
            out.println("     <noderef id=\"" + edge.getEnd().getUID()
                  + "\" port=\"" + edge.getEndPort() + "\"/>");
            out.println("    </to>");
            out.println("   </edge>");
            
         }
         
         out.println("  </board>");
      }
      out.println(" </boards-map>");
   }
   
   public static void main(String[] args)
   {
      Level l = new Level();
      l.outputXML(System.out);
   }
}
