package levelBuilder;

import java.util.Collections;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Iterator;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

import level.Board;
import level.Chute;
import level.Intersection;
import level.Intersection.Kind;
import level.Subnetwork;
import checkers.nullness.quals.Nullable;


/**
 * 
 * A mutable class used for building a board from source code. Used to bridge
 * the gap between the Board structure and the information required by the
 * translation algorithm.<br/>
 * <br/>
 * Implements eternal equality.<br/>
 * <br/>
 * Specification Field: board: Board // The board that this BoardBuilder is
 * building<br/>
 * <br/>
 * Specification Field: levelBuilder: LevelBuilder // The LevelBuilder that
 * represents the Level that "board" belongs in -- stores information global to
 * the level that is needed for construction, but not gameplay<br/>
 * <br/>
 * Specification Field: varToCurrentEdge: Map<String, Chute> // For a given
 * variable name, maps to a prototypical base Chute for its type. The chute
 * objects contained in this Map will not be part of the Board. They are simply
 * used to keep track of type information for variables.<br/>
 * <br/>
 * "return" is always a key in this Map. Other chutes can merge into it,
 * indicating that they can be the return value for this method.<br/>
 * <br/>
 * Specification Field: active: boolean // indicates whether this BoardBuilder
 * is currently constructing a Board. If false, no changes are allowed to the
 * contained Board. Active is set to false as soon as the contained Board is
 * returned. This is for the following reasons:<br/>
 * <br/>
 * It only makes sense for a client to want the Board once it is complete, so
 * this does no harm.<br/>
 * <br/>
 * Once a reference to the Board is returned, it could be modified externally.
 * That means that this class can no longer provide any guarantees about its
 * contents, so it is safer to just stop construction.<br/>
 * 
 * @author Nathaniel Mote
 */

/*
 * Notes:
 * 
 * - This class is currently a prototype. The interface may change at any time.
 * 
 * - Please don't judge my code. It's still fairly ugly and undocumented.
 * 
 * TODO clean up code
 */

public class BoardBuilder
{
   private final BoardManager boardManager;
   
   private final LevelBuilder levelBuilder;
   
   /* Maps a variable name to the current Chute that represents it */
   private final Map<String, Chute> varToCurrentEdge;
   
   private final Set<Chute> currentEdges;
   
   /**
    * Maps a furthest Chute to the Set<Chute> that it is linked to, in the sense
    * defined by {@link level.Level Level}
    */
   private final Map<Chute, Set<Chute>> chuteToLinkedChutes;
   
   /**
    * Contains elements transferred from {@link #chuteToLinkedChutes
    * chuteToLinkedChutes.values()} after the variables they represent are no
    * longer active, so there is no longer an appropriate key chute
    */
   private final Set<Set<Chute>> linkedChuteSets;
   
   private boolean active;
   
   private final boolean constructor;
   
   // Adapter for Board that allows half-edges. That is, edges are allowed to be
   // added without an end point
   private class BoardManager
   {
      private Board board;
      
      // start Board delegate methods
      
      /**
       * @see java.lang.Object#hashCode()
       */
      @Override
      public int hashCode()
      {
         return board.hashCode();
      }
   
      /**
       * @see java.lang.Object#equals(java.lang.Object)
       */
      @Override
      public boolean equals(Object obj)
      {
         return board.equals(obj);
      }
   
      /**
       * @see level.Board#addNode(level.Intersection)
       */
      public void addNode(Intersection node)
      {
         board.addNode(node);
      }
   
      /**
       * @see level.Board#addEdge(level.Intersection, int, level.Intersection, int, level.Chute)
       */
      public void addEdge(Intersection start, int startPort, Intersection end,
            int endPort, Chute edge)
      {
         board.addEdge(start, startPort, end, endPort, edge);
      }
   
      /**
       * @see level.Board#nodesSize()
       */
      public int nodesSize()
      {
         return board.nodesSize();
      }
   
      /**
       * @see level.Board#edgesSize()
       */
      public int edgesSize()
      {
         return board.edgesSize();
      }
   
      /**
       * @see level.Board#getNodes()
       */
      public Set<Intersection> getNodes()
      {
         return board.getNodes();
      }
   
      /*
       * @see java.lang.Object#toString()
       */
      @Override
      public String toString()
      {
         return board.toString();
      }
   
      /**
       * @see level.Board#getEdges()
       */
      public Set<Chute> getEdges()
      {
         return board.getEdges();
      }
   
      /**
       * @see level.Board#getIncomingNode()
       */
      public Intersection getIncomingNode()
      {
         return board.getIncomingNode();
      }
   
      /**
       * @see level.Board#getOutgoingNode()
       */
      public Intersection getOutgoingNode()
      {
         return board.getOutgoingNode();
      }
   
      /**
       * @see level.Board#contains(java.lang.Object)
       */
      public boolean contains(Object elt)
      {
         return board.contains(elt) || halfEdgeToStartNode.containsKey(elt);
      }
   
      /**
       * @see level.Board#isActive()
       */
      public boolean isActive()
      {
         return board.isActive();
      }
   
      /**
       * 
       * @see level.Board#deactivate()
       */
      public void deactivate()
      {
         board.deactivate();
      }
      
      // End board delegate methods
      
      public Board getBoard()
      {
         if (!halfEdgeToStartNode.keySet().isEmpty())
            throw new IllegalStateException(
                  "getBoard called while there are still half edges");
         return board;
      }
      
      private Map<Chute, Intersection> halfEdgeToStartNode;
      private Map<Chute, Integer> halfEdgeToNodePort;
   
      public BoardManager()
      {
         board = new Board();
         halfEdgeToStartNode = new LinkedHashMap<Chute, Intersection>();
         halfEdgeToNodePort = new LinkedHashMap<Chute, Integer>();
      }
      
      public Set<Chute> currentHalfEdges()
      {
         return Collections.unmodifiableSet(halfEdgeToStartNode.keySet());
      }
      
      /**
       * 
       * @param start Must be a node in this
       * @param startPort Must be a valid output port number for start
       * @param edge Must not be in this
       */
      public void addHalfEdge(Intersection start, int startPort, Chute edge)
      {
         halfEdgeToStartNode.put(edge, start);
         halfEdgeToNodePort.put(edge, startPort);
      }
      
      public void finishHalfEdge(Intersection end, int endPort, Chute edge)
      {
         addEdge(halfEdgeToStartNode.get(edge), halfEdgeToNodePort.get(edge), end, endPort, edge);
         halfEdgeToStartNode.remove(edge);
         halfEdgeToNodePort.remove(edge);
      }
      
   }

   private static final boolean CHECK_REP_ENABLED = true;
   
   private void checkRep()
   {
      if (CHECK_REP_ENABLED)
      {
         // Representation Invariant:
         
         // - chuteToFurthestNode.keySet(), chuteToNodePort.keySet(), and
         // chuteToLinkedChutes.keySet() must be equal
         //ensure(chuteToFurthestNode.keySet().equals(chuteToNodePort.keySet()));
         //ensure(chuteToNodePort.keySet().equals(chuteToLinkedChutes.keySet()));
         
         // - The elements in varToCurrentEdge.values() are a subset of
         // chuteToFurthestNode.keySet() and chuteToNodePort.keySet()
         //chuteToFurthestNode.keySet().containsAll(varToCurrentEdge.values());
         
         // - for all Intersections n in chuteToFurthestNode.values(),
         // board.contains(n);
         //ensure(boardManager.getNodes().containsAll(chuteToFurthestNode.values()));
         
         // - active <--> board.isActive()
         ensure(active == boardManager.isActive());
         
         // - For every Chute c in varToCurrentEdge.values():
         // - - 
         
         // For every Chute c in chuteToLinkedChutes.keySet():
         // chuteToLinkedChutes.get(c).contains(c);
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
    * Creates a new BoardBuilder with the given LevelBuilder. Uses, as a
    * template, the fields present in LevelBuilder. If constructor is false,
    */
   protected BoardBuilder(LevelBuilder lb, boolean constructor)
   {
      active = true;
      
      this.constructor = constructor;
      
      varToCurrentEdge = new HashMap<String, Chute>();
      chuteToLinkedChutes = new HashMap<Chute, Set<Chute>>();
      linkedChuteSets = new HashSet<Set<Chute>>();
      
      levelBuilder = lb;
      boardManager = new BoardManager();
      
      currentEdges = boardManager.currentHalfEdges();
      
      Intersection incoming = Intersection.factory(Kind.INCOMING);
      boardManager.addNode(incoming);
      
      if (!constructor)
      {
         // Copy the chutes in levelBuilder.getFields() and attach them to
         // incoming
         // in the proper order. Also, for each named field, add it to
         // varToCurrentEdge
         List<Chute> fields = levelBuilder.getFields();
         
         int currentIncomingPort = 0;
         for (Chute template : fields)
         {
            Chute c = template.copy();
            // TODO find name
            // varToCurrentEdge.put(c.getName(), c);

            boardManager.addHalfEdge(incoming, currentIncomingPort++, c);
            
            chuteToLinkedChutes.put(c, new LinkedHashSet<Chute>());
            chuteToLinkedChutes.get(c).add(c);
            
            // TODO change so that fields' aux chute are all linked, too
            // TODO find name
            // levelBuilder.addChuteToField(c.getName(), c);
         }
      }
      checkRep();
   }
   
   /**
    * Creates a new BoardBuilder with the given LevelBuilder. Uses, as a
    * template, the fields present in LevelBuilder.
    */
   protected BoardBuilder(LevelBuilder lb)
   {
      this(lb, false);
   }
   
   /**
    * Adds the named variable to this BoardBuilder. More specifically, creates a
    * node of the given type and attaches a Chute to it. The given Chute object
    * is used only as a prototype, and will not be modified<br/>
    * <br/>
    * Requires:<br/>
    * active;<br/>
    * vartype.getName() != null;<br/>
    * vartype.getName() must not be present in this BoardBuilder;<br/>
    * startType must be able to have 0 input ports and 1 output port
    */
   public void addVar(Chute vartype, Intersection.Kind startType)
   {
      if (!active)
         throw new IllegalStateException(
               "variable added to inactive BoardBuilder");
      
      Intersection newNode = Intersection.factory(startType);
      boardManager.addNode(newNode);
      
      Chute c = vartype.copy();
      // TODO find name
      // varToCurrentEdge.put(c.getName(), c);
      
      boardManager.addHalfEdge(newNode, 0, c);
      
      chuteToLinkedChutes.put(c, new LinkedHashSet<Chute>());
      chuteToLinkedChutes.get(c).add(c);
      
      checkRep();
   }
   
   /**
    * Adds a pinch point on the furthest chute associated with var<br/>
    * <br/>
    * Requires:<br/>
    * active;<br/>
    * the named variable is present in this BoardBuilder
    */
   // TODO change String to whatever we end up using
   public void addPinchToVar(String var)
   {
      varToCurrentEdge.get(var).setPinched(true);
      checkRep();
   }
   
   /**
    * Adds the given sub-boards to this. For each of the chutes, there is a
    * simple SPLIT at the top and a MERGE at the bottom.<br/>
    * <br/>
    * Requires:<br/>
    * active;<br/>
    * bb's input and output ports all correspond to variables in this board<br/>
    * <br/>
    * Modifies: this
    */
   public void addSubBoards(Set<BoardBuilder> bb)
   {
      checkRep();
      throw new RuntimeException("Not yet implemented");
   }
   
   /**
    * Adds the given subnetwork, with the given args and return value, to the
    * board that this is building<br/>
    * <br/>
    * Requires:<br/>
    * active;<br/>
    * name is, or will be, a valid board name in levelBuilder;<br/>
    * all args and ret are valid variables in this.<br/>
    * <br/>
    * Modifies: this
    */
   public void addSubnetwork(String name, List<String> args, @Nullable String ret)
   {
      Subnetwork node = Intersection.subnetworkFactory(name);
      
      boardManager.addNode(node);
      
      for (String s : args)
      {
         Chute originalChute = varToCurrentEdge.get(s);
         Intersection splitNode = Intersection.factory(Kind.SPLIT);
         
         addNodeToChute(originalChute, splitNode, 0, 0);
         
         
      }
      
      checkRep();
      throw new RuntimeException("Not yet implemented");
   }
   
   /**
    * Represents an assignment from "from" to "to."<br/>
    * Specifically, puts a split in the from chute and an end on the to chute,
    * then merging one of the branches of from with to.<br/>
    * <br/>
    * Requires:<br/>
    * given variables are both present<br/>
    * <br/>
    * Modifies: this
    */
   public void assignment(String to, String from)
   {
      checkRep();
      throw new RuntimeException("Not yet implemented");
   }
   
   /**
    * Represents an assignment from an expression of type represented by "from"
    * to "to."<br/>
    * <br/>
    * Specifically, puts an end on the to chute, then creates an Intersection
    * out of from and puts that at the start of a new Chute for the to variable<br/>
    * <br/>
    * Requires:<br/>
    * to is present;<br/>
    * from can have 0 input ports and 1 output port<br/>
    * <br/>
    * Modifies: this
    */
   // TODO retrofit so that it works with aux chutes
   public void assignment(String to, Intersection.Kind from)
   {
      if (varToCurrentEdge.containsKey(to))
      {
         Intersection end = Intersection.factory(Kind.END);
         boardManager.addNode(end);
         
         Chute oldChute = varToCurrentEdge.get(to);
         
         boardManager.finishHalfEdge(end, 0, oldChute);
         
         varToCurrentEdge.remove(to);
         
         Intersection newNode = Intersection.factory(from);
         boardManager.addNode(newNode);
         
         Chute newChute = oldChute.copy();
         
         varToCurrentEdge.put(to, newChute);
         
         boardManager.addHalfEdge(newNode, 0, newChute);
         
         chuteToLinkedChutes.put(newChute, chuteToLinkedChutes.get(oldChute));
         chuteToLinkedChutes.get(newChute).add(newChute);
         chuteToLinkedChutes.remove(oldChute);
         
      }
      else if (constructor)
      {
         Chute fieldtype = null;
         for (Chute c : levelBuilder.getFields())
         {
            // TODO find name
            // if (c.getName().equals(to))
            {
               fieldtype = c;
               break;
            }
         }
         if (fieldtype != null)
         {
            addVar(fieldtype, from);
         }
         else
         {
            throw new IllegalArgumentException("Variable " + to + " not present");
         }
      }
      else
      {
         throw new IllegalArgumentException("Variable " + to + " not present");
      }
      checkRep();
      
   }
   
   /**
    * Makes the chutes for the given variable flow into the return output chute<br/>
    * <br/>
    * Requires: given variable is present<br/>
    * <br/>
    * Modifies: this
    */
   // TODO determine what to do if client tries to modify this variable after
   public void returnVar(String var)
   {
      checkRep();
      throw new RuntimeException("Not yet implemented");
   }
   
   /**
    * Returns the board that this BoardBuilder is building<br/>
    * <br/>
    * Sets active to false<br/>
    * <br/>
    * Requires: active<br/>
    * <br/>
    * Modifies: this
    * 
    * @return Board b, where !b.isActive()
    */
   protected Board getBoard()
   {
      /*
       * Behavior:
       * 
       * - Attach all fields and argument chutes to the bottom (the base chute
       * type doesn't flow through, but it's easier to just attach it for the
       * sake of consistency)
       * 
       * - If there is anything attached to the return chute, attach the return
       * chute to the bottom
       */
      active = false;
      
      Intersection outgoing = Intersection.factory(Kind.OUTGOING);
      boardManager.addNode(outgoing);
      
      List<Chute> fields = levelBuilder.getFields();
      
      // Attach all the field and argument chutes to the outgoing node.
      // TODO add support for return values
      int currentOutPort = 0;
      for (Chute f : fields)
      {
         // TODO find name
         String fieldName = "placeholder"; // f.getName();
         Chute lastChute = varToCurrentEdge.get(fieldName);
         
         levelBuilder.addChuteToField(fieldName, lastChute);
         
         boardManager.finishHalfEdge(outgoing, currentOutPort++, lastChute);
      }
      
      boardManager.deactivate();
      
      // add all of the remaining sets of linked chutes to linkedChuteSets
      linkedChuteSets.addAll(chuteToLinkedChutes.values());
      
      for (Set<Chute> toLink : linkedChuteSets)
         levelBuilder.addLinkedEdgeSet(toLink);
      
      return boardManager.getBoard();
      
   }
   
   /**
    * Returns levelBuilder
    */
   public LevelBuilder getLevelBuilder()
   {
      return levelBuilder;
   }
   
   /**
    * Returns active
    */
   public boolean isActive()
   {
      return active;
   }
   
   /**
    * Adds the n to the end of c and creates a copy of c to as the new furthest edge<br/>
    * <br/>
    * Modifies: this;
    * 
    * @param c
    * <br/>
    * if c.getName() != null, then varToCurrentEdge.get(c.getName()) == c;<br/>
    * chuteToFurthestNode.containsKey(c);<br/>
    * chuteToNodePort.containsKey(c);<br/>
    * @param n
    * !board.contains(n);
    * @param inPort
    * The input port of n to attach c to
    * @param outPort
    * The output port of n to attach c's copy to
    * 
    */
   private void addNodeToChute(Chute c, Intersection n, int inPort, int outPort)
   {
      if (boardManager.contains(n))
         throw new IllegalArgumentException("board already contains n");
      
      boardManager.addNode(n);
      
      boardManager.addHalfEdge(n, inPort, c);
      
      Chute nextChute = c.copy();
      // TODO find name
      String name = null;// nextChute.getName();
      if (name != null)
         varToCurrentEdge.put(name, nextChute);
      
      boardManager.addHalfEdge(n, outPort, nextChute);
      
      chuteToLinkedChutes.put(nextChute, chuteToLinkedChutes.get(c));
      chuteToLinkedChutes.get(nextChute).add(nextChute);
      
   }
}
