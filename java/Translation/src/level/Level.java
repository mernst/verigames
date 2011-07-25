package level;

import java.io.PrintStream;
import java.util.Arrays;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.Map;
import java.util.Set;

import level.Intersection.Kind;

/**
 * 
 * A mutable (until deactivated) data structure that represents a complete level<br/>
 * <br/>
 * Specification Field: linkedEdgeClasses: Set<Set<Chute>> // Contains
 * equivalence classes of Chutes, as defined by the following equivalence
 * relation<br/>
 * <br/>
 * Let R be an equivalence relation on the set of all Chutes such that:<br/>
 * aRb <--> a and b necessarily have the same width.<br/>
 * <br/>
 * Specification Field: boards: Set<Board> // represents the set of all boards
 * in this level<br/>
 * <br/>
 * Specification Field: boardNames: Map<String, Board> // maps the name of a
 * method to its board<br/>
 * <br/>
 * Specification Field: active : boolean // true iff this can be part of a
 * structure that is still under construction. once active is set to false, this
 * becomes immutable.<br/>
 * 
 * @author Nathaniel Mote
 */

public class Level
{
   private Set<Set<Chute>> linkedEdgeClasses;
   
   // TODO change String, if necessary, to whatever we end up using
   private Map<String, Board> boardNames;
   
   private boolean active = true;
   
   private static final boolean CHECK_REP_ENABLED = true;
   
   /**
    * Enforces the Representation Invariant
    */
   private void checkRep()
   {
      // Representation Invariant:
      if (CHECK_REP_ENABLED)
      {
         Set<Chute> encountered = new HashSet<Chute>();
         for (Set<Chute> s : linkedEdgeClasses)
         {
            
            // No chute can be contained in more than one set in
            // linkedEdgeClasses
            for (Chute c : s)
            {
               ensure(!encountered.contains(c));
               encountered.add(c);
            }
            
            // No set in linkedEdgeClasses may be empty
            ensure(!s.isEmpty());
            
            /*
             * No set in linkedEdgeClasses may have size 1 (the fact that a
             * chute is linked to itself need not be represented)
             */
            ensure(s.size() != 1);
            
            /*
             * All chutes contained in sets contained in linkedEdgeClasses must
             * also be contained contained by some Board in boardNames.values()
             * 
             * Not checked for effiency's sake
             */
         }
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
    * Creates a new Level object with an empty linkedEdgeMap, boards, and
    * boardNames
    */
   public Level()
   {
      linkedEdgeClasses = new LinkedHashSet<Set<Chute>>();
      boardNames = new LinkedHashMap<String, Board>();
      checkRep();
   }
   
   /**
    * Makes it so that the given chutes are equivalent under the relation R
    * defined for linkedEdgeClasses. In other words, for all a, b in toLink, aRb<br/>
    * <br/>
    * Requires: every Chute in toLink must be contained in a Board in boardNames<br/>
    * Modifies: this <br/>
    * <br/>
    * Runs in O(m*n) time, where m is linkedEdgeClasses.size() and n is
    * toLink.length
    * 
    * @param toLink
    * The set of Chutes to make equivalent under the equivalence relation R
    * 
    */
   public void makeLinked(Chute... toLink)
   {
      if (toLink.length > 1)
      {
         /*
          * Contains the sets that should be removed from linkedEdgeClasses
          * because they will be deprecated by the newly created equivalence
          * class
          */
         Set<Set<Chute>> toRemove = new LinkedHashSet<Set<Chute>>();
         
         /*
          * The new equivalence class to be added to linkedEdgeClasses. It will
          * at least have all of the elements in toLink.
          */
         Set<Chute> newEquivClass = new LinkedHashSet<Chute>(
               Arrays.asList(toLink));
         
         for (Set<Chute> linked : linkedEdgeClasses)
         {
            for (Chute c : toLink)
            {
               if (linked.contains(c))
               {
                  toRemove.add(linked);
                  newEquivClass.addAll(linked);
               }
            }
         }
         
         linkedEdgeClasses.removeAll(toRemove);
         
         linkedEdgeClasses.add(newEquivClass);
         checkRep();
      }
   }
   
   /**
    * Functions identically to {@link #makeLinked(Chute...)}
    * 
    * @param toLink
    * @see #makeLinked(Chute...)
    */
   public void makeLinked(Set<Chute> toLink)
   {
      makeLinked(toLink.toArray(new Chute[0]));
   }
   
   
   /**
    * Returns true iff all of the chutes in the given set are linked
    */
   public boolean areLinked(Set<Chute> chutes)
   {
      // A single chute is always linked to itself
      if (chutes.size() == 1)
         return true;
      
      for (Set<Chute> s : linkedEdgeClasses)
      {
         if (s.containsAll(chutes))
            return true;
      }
      return false;
   }
   
   /**
    * Adds b to boards, and adds the mapping from name to b to boardNames<br/>
    * 
    * Requires: b is not in boards, name is not in boardNames.keySet()<br/>
    * <br/>
    * Modifies: this<br/>
    * 
    */
   public void addBoard(String name, Board b)
   {
      boardNames.put(name, b);
      checkRep();
   }
   
   /**
    * Returns a shallow copy of boards
    */
   public Set<Board> boards()
   {
      return new LinkedHashSet<Board>(boardNames.values());
   }
   
   /**
    * Returns the Board that name maps to in boardNames, or null if it maps to
    * nothing
    */
   public/* @Nullable */Board getBoard(String name)
   {
      return boardNames.get(name);
   }
   
   /**
    * Prints the text of the XML representation of this Level to the given
    * PrintStream<br/>
    * <br/>
    * Requires:<br/>
    * !this.isActive();<br/>
    * out is open and ready to be written to<br/>
    * Modifies: out<br/>
    */
   public void outputXML(PrintStream out)
   {
      if (this.isActive())
         throw new IllegalStateException("outputXML called on active Level");
      
      out.println("<level>");
      outputlinkedEdgeClasses(out);
      outputBoardsMap(out);
      out.println("</level>");
   }
   
   /**
    * Prints the linked edge section of the xml to out, indented by one space<br/>
    * <br/>
    * Requires: For all Chutes c in Sets in linkedEdgeClasses, !c.isActive()<br/>
    * <br/>
    * Modifies: out
    * 
    */
   private void outputlinkedEdgeClasses(PrintStream out)
   {
      out.println(" <linked-edges>");
      
      // Output all linked edges explicitly listed in linkedEdgeClasses
      Set<Chute> alreadyPrintedEdges = new HashSet<Chute>();
      for (Set<Chute> set : linkedEdgeClasses)
      {
         out.println("  <edge-set>");
         for (Chute c : set)
         {
            if (c.isActive())
               throw new IllegalStateException(
                     "outputlinkedEdgeClasses called when linkedEdgeClasses contains active Chute");
            out.println("   <edgeref id=\"e" + c.getUID() + "\"/>");
            alreadyPrintedEdges.add(c);
         }
         out.println("  </edge-set>");
      }
      
      // Output all remaining edges -- edges not listed are in equivalence
      // classes of size 1
      
      for (Board b : boards())
      {
         for (Chute c : b.getEdges())
         {
            if (!alreadyPrintedEdges.contains(c))
            {
               out.println("  <edge-set>");
               if (c.isActive())
                  throw new IllegalStateException(
                        "outputlinkedEdgeClasses called when linkedEdgeClasses contains active Chute");
               out.println("   <edgeref id=\"e" + c.getUID() + "\"/>");
               out.println("  </edge-set>");
            }
         }
      }
      
      out.println(" </linked-edges>");
   }
   
   /**
    * Prints the board map section of the xml to out, indented by one space<br/>
    * <br/>
    * Requires: For all nodes n, edges e in any Board contained in this:
    * !n.isActive() && !e.isActive() <br/>
    * <br/>
    * Modifies: out<br/>
    */
   // TODO add "editable" attribute to edge output (involves editing DTD)
   private void outputBoardsMap(PrintStream out)
   {
      if (active)
         throw new IllegalStateException("outputBoardsMap called on active Level");
      
      out.println(" <boards>");
      for (String name : boardNames.keySet())
      {
         Board board = boardNames.get(name);
         out.println("  <board name=\"" + name + "\">");
         
         for (Intersection node : board.getNodes())
         {
            if (node.isActive())
               throw new IllegalStateException("active Intersection in Level while printing XML");
            
            out.print("   <node kind=\"" + node.getIntersectionKind()+ "\"");
            if (node.getIntersectionKind() == Kind.SUBNETWORK)
            {
               if (node.isSubnetwork())
                  out.print(" name=\"" + node.asSubnetwork().getSubnetworkName() + "\"");
               else
                  throw new RuntimeException("node " + node + " has kind subnetwork but isSubnetwork returns false");
            }
            out.println(" id=\"n" + node.getUID() + "\">");
            out.println("    <input>");
            
            Chute input = node.getInputChute(0);
            for (int i = 0; input != null; input = node.getInputChute(++i))
               out.println("     <port num=\"" + i + "\" edge=\"e"
                     + input.getUID() + "\"/>");
            
            out.println("    </input>");
            out.println("    <output>");
            
            Chute output = node.getOutputChute(0);
            for (int i = 0; output != null; output = node.getOutputChute(++i))
               out.println("     <port num=\"" + i + "\" edge=\"e"
                     + output.getUID() + "\"/>");
            
            out.println("    </output>");
            out.println("   </node>");
         }
         
         for (Chute edge : board.getEdges())
         {
            if (edge.isActive())
               throw new IllegalStateException("active Chute in Level while printing XML");
            
            out.println("   <edge var=\"" + edge.getName() + "\" pinch=\""
                  + edge.isPinched() + "\" width=\""
                  + (edge.isNarrow() ? "narrow" : "wide") + "\" id=\"e"
                  + edge.getUID() + "\">");
            
            out.println("    <from>");
            // TODO do something about this nullness warning
            out.println("     <noderef id=\"n" + edge.getStart().getUID()
                  + "\" port=\"" + edge.getStartPort() + "\"/>");
            out.println("    </from>");
            out.println("    <to>");
            // TODO do something about this nullness warning
            out.println("     <noderef id=\"n" + edge.getEnd().getUID()
                  + "\" port=\"" + edge.getEndPort() + "\"/>");
            out.println("    </to>");
            out.println("   </edge>");
            
         }
         
         out.println("  </board>");
      }
      out.println(" </boards>");
   }
   
   /**
    * Returns active
    */
   public boolean isActive()
   {
      return active;
   }
   
   /**
    * Sets active to false, deactivates all contained Boards<br/>
    * <br/>
    * Requires:<br/>
    * active;<br/>
    * all Boards in boards are in a state in which they can be deactivated
    */
   public void deactivate()
   {
      if (!active)
         throw new IllegalStateException("Mutation attempted on inactive Level");
      active = false;
      for (Board b : boardNames.values())
         b.deactivate();
   }
}
