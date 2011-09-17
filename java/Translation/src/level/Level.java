package level;

import java.io.PrintStream;
import java.util.Arrays;
import java.util.Collections;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.Map;
import java.util.Set;

import level.Intersection.Kind;

/**
 * A mutable level for Pipe Jam. A {@code Level} consists of any number of
 * {@link Board}s, each associated with a unique name.<br/>
 * <br/>
 * A {@code Level} also keeps track of which {@link Chute}s in the contained
 * {@code Board}s are linked (see below).<br/>
 * <br/>
 * Specification Field: {@code linkedEdgeClasses} : {@code Set<Set<Chute>>}
 * // Contains equivalence classes of {@code Chute}s, as defined by the
 * following equivalence relation<br/>
 * <br/>
 * Let R be an equivalence relation on the set of all {@code Chute}s such that:<br/>
 * aRb <--> a and b necessarily have the same width. That is, when a changes
 * width, b must follow, and vice-versa.<br/>
 * <br/>
 * Specification Field: {@code boards} : {@code Set<Board>}
 * // represents the set of all boards in this level<br/>
 * <br/>
 * Specification Field: {@code boardNames} : {@code Map<String, Board>}
 * // maps the name of a method to its {@code Board}<br/>
 * <br/>
 * Specification Field: {@code active} : {@code boolean} // {@code true} iff
 * {@code this} can still be modified. Once {@code active} is set to
 * {@code false}, {@code this} becomes immutable.
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
      if (!CHECK_REP_ENABLED)
         return;
      
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
          * No set in linkedEdgeClasses may have size 1 (the fact that a chute
          * is linked to itself need not be represented)
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
    * Creates a new {@code Level} with an empty {@code linkedEdgeClasses},
    * {@code boards}, and {@code boardNames}
    */
   public Level()
   {
      linkedEdgeClasses = new LinkedHashSet<Set<Chute>>();
      boardNames = new LinkedHashMap<String, Board>();
      checkRep();
   }
   
   /**
    * Makes it so that the given {@link Chute}s are equivalent under the
    * relation R defined for {@code linkedEdgeClasses}. In other words, for all
    * a, b in {@code toLink}, aRb<br/>
    * <br/>
    * Requires: every {@code Chute} in {@code toLink} must be contained in a
    * {@link Board} in {@code boards}<br/>
    * <br/>
    * Modifies: {@code this}<br/>
    * <br/>
    * Runs in O(m*n) time, where m is {@code linkedEdgeClasses.size()} and n is
    * {@code toLink.length}
    * 
    * @param toLink
    * The {@code Chute}s to make equivalent under the equivalence relation R
    * 
    * @see #makeLinked(Set)
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
    * Functions identically to {@link #makeLinked(Chute...)}, except the
    * elements to link are specified by a {@code Set} instead of an array
    * 
    * @param toLink
    * @see #makeLinked(Chute...)
    */
   public void makeLinked(Set<Chute> toLink)
   {
      makeLinked(toLink.toArray(new Chute[0]));
   }
   
   
   /**
    * Returns {@code true} iff all of the {@code Chute}s in {@code chutes} are linked.
    * @param chutes
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
    * Adds {@code b} to {@code boards}, and adds the mapping from {@code name}
    * to {@code b} to {@code boardNames}<br/>
    * <br/>
    * Modifies: {@code this}<br/>
    * 
    * @param b
    * The {@link Board} to add to {@code boards}. Must not be contained in
    * {@code boards}
    * @param name
    * The name to associate with {@code b}. Must not be contained in
    * {@code boardNames.keySet()}
    */
   public void addBoard(String name, Board b)
   {
      if (boardNames.containsKey(name))
         throw new IllegalArgumentException("name \"" + name + "\" already in use");
      if (boardNames.containsValue(b))
         throw new IllegalArgumentException("Board " + b + " already contained");
      boardNames.put(name, b);
      checkRep();
   }
   
   /**
    * Return an unmodifiable {@code Map} view on {@code boardNames}. The
    * returned {@code Map} is backed by {@code this}, so changes in {@code
    * this} will be reflected in the returned {@code Map}.
    */
   public Map<String, Board> boards()
   {
      return Collections.unmodifiableMap(boardNames);
   }
   
   /**
    * Returns the {@code Board} to which {@code name} maps in {@code boardNames}
    * , or {@code null} if it maps to nothing
    */
   public/* @Nullable */Board getBoard(String name)
   {
      return boardNames.get(name);
   }
   
   /**
    * Prints the text of the XML representation of {@code this} to the given
    * {@code PrintStream}<br/>
    * <br/>
    * Requires:<br/>
    * - {@link #isActive() !this.isActive()}<br/>
    * - {@code out} is open<br/>
    * - For every {@link Chute} c in every {@code Set} in
    * {@code linkedEdgeClasses}, {@link Chute#isActive() !c.isActive()}<br/>
    * - For all nodes {@code n}, edges {@code e} in any {@link Board}
    * contained in {@code this}: {@link Intersection#isActive() !n.isActive()}
    * {@code &&} {@link Chute#isActive() !e.isActive()}<br/>
    * <br/>
    * Modifies: {@code out}<br/>
    */
   protected void outputXML(String name, PrintStream out)
   {
      if (this.isActive())
         throw new IllegalStateException("outputXML called on active Level");
      
      out.println("<level name=\"" + name + "\">");
      outputlinkedEdgeClasses(out);
      outputBoardsMap(out);
      out.println("</level>");
   }
   
   /**
    * Prints the linked edge section of the XML to {@code out}<br/>
    * <br/>
    * Requires: For every {@link Chute} c in every {@code Set} in
    * {@code linkedEdgeClasses}, {@link Chute#isActive() !c.isActive()}<br/>
    * <br/>
    * Modifies: {@code out}
    * 
    * @param out
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
      
      for (Board b : boards().values())
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
    * Prints the board map section of the XML to {@code out}.<br/>
    * <br/>
    * Requires: For all nodes {@code n}, edges {@code e} in any {@link Board}
    * contained in {@code this}: {@link Intersection#isActive() !n.isActive()}
    * {@code &&} {@link Chute#isActive() !e.isActive()}<br/>
    * <br/>
    * Modifies: {@code out}<br/>
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
            
            Chute input = node.getInput(0);
            for (int i = 0; input != null; input = node.getInput(++i))
               out.println("     <port num=\"" + i + "\" edge=\"e"
                     + input.getUID() + "\"/>");
            
            out.println("    </input>");
            out.println("    <output>");
            
            Chute output = node.getOutput(0);
            for (int i = 0; output != null; output = node.getOutput(++i))
               out.println("     <port num=\"" + i + "\" edge=\"e"
                     + output.getUID() + "\"/>");
            
            out.println("    </output>");
            
            double x = node.getX();
            double y = node.getY();
            if (x >= 0 && y >= 0)
            {
               out.println("<layout>");
               out.println("<x>"+x+"</x>");
               out.println("<y>"+y+"</y>");
               out.println("</layout>");
            }
            
            out.println("   </node>");
         }
         
         for (Chute edge : board.getEdges())
         {
            if (edge.isActive())
               throw new IllegalStateException("active Chute in Level while printing XML");
            
            String edgeName = null;
            {
               Set<String> names = board.getChuteNames(edge);
               if (!names.isEmpty())
                  edgeName = names.iterator().next();
            }
            
            out.println("   <edge var=\"" + edgeName + "\" pinch=\""
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
    * Returns {@code active}
    */
   public boolean isActive()
   {
      return active;
   }
   
   /**
    * Sets {@code active} to {@code false}, deactivates all contained
    * {@link Board}s<br/>
    * <br/>
    * Requires:<br/>
    * - {@link #isActive() this.isActive()}<br/>
    * - all {@code Board}s in {@code boards} are in a state in which they can be
    * deactivated
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
