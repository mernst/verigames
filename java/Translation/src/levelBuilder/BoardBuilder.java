package levelBuilder;

import java.util.HashMap;
import java.util.Iterator;
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
   private final Board board;
   
   private final LevelBuilder levelBuilder;
   
   /* Maps a variable name to the current Chute that represents it */
   private Map<String, Chute> varToCurrentEdge;
   
   /*
    * Maps a Chute in varToCurrentEdge.values() to the Intersection and port
    * number that it will attach to.
    */
   private Map<Chute, Intersection> chuteToFurthestNode;
   private Map<Chute, Integer> chuteToNodePort;
   
   private boolean active;
   
   private static final boolean CHECK_REP_ENABLED = true;
   
   private void checkRep()
   {
      if (CHECK_REP_ENABLED)
      {
         // Representation Invariant:
         
         // - chuteToFurthestNode.keySet() and chuteToNodePort.keySet() must be
         // equal
         ensure(chuteToFurthestNode.keySet().equals(chuteToNodePort.keySet()));
         
         // - The elements in varToCurrentEdge.values() are a subset of
         // chuteToFurthestNode.keySet() and chuteToNodePort.keySet()
         chuteToFurthestNode.keySet().containsAll(varToCurrentEdge.values());
         
         // - for all Intersections n in chuteToFurthestNode.values(),
         // board.contains(n);
         ensure(board.getNodes().containsAll(chuteToFurthestNode.values()));
         
         // - active <--> board.isActive()
         ensure(active == board.isActive());
         
         // - For every Chute c in varToCurrentEdge.values():
         // - - 
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
    * Creates a new BoardBuilder with the given LevelBuilder. Uses, as a
    * template, the fields present in LevelBuilder.
    */
   protected BoardBuilder(LevelBuilder lb)
   {
      active = true;
      
      varToCurrentEdge = new HashMap<String, Chute>();
      chuteToFurthestNode = new HashMap<Chute, Intersection>();
      chuteToNodePort = new HashMap<Chute, Integer>();
      
      levelBuilder = lb;
      board = new Board();
      Intersection incoming = Intersection.factory(Kind.INCOMING);
      board.addNode(incoming);
      
      // Copy the chutes in levelBuilder.getFields() and attach them to incoming
      // in the proper order. Also, for each named field, add it to
      // varToCurrentEdge
      List<Chute> fields = levelBuilder.getFields();
      
      int currentIncomingPort = 0;
      for (Chute template : fields)
      {
         Chute c = template.copy();
         varToCurrentEdge.put(c.getName(), c);
         chuteToFurthestNode.put(c, incoming);
         chuteToNodePort.put(c, currentIncomingPort++);
         
         // Perform a preorder traversal of the auxiliary chutes tree
         Iterator<Chute> auxChuteTraversal = c.traverseAuxChutes();
         while (auxChuteTraversal.hasNext())
         {
            Chute aux = auxChuteTraversal.next();
            chuteToFurthestNode.put(aux, incoming);
            chuteToNodePort.put(aux, currentIncomingPort++);
         }
      }
      checkRep();
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
      if (vartype.getName() == null)
         throw new IllegalArgumentException(
               "vartype.getName() must not be null");
      if (varToCurrentEdge.containsKey(vartype.getName()))
         throw new IllegalArgumentException(vartype.getName()
               + " already exists in this BoardBuilder");
      
      Intersection newNode = Intersection.factory(startType);
      board.addNode(newNode);
      
      Chute c = vartype.copy();
      varToCurrentEdge.put(c.getName(), c);
      
      chuteToFurthestNode.put(c, newNode);
      chuteToNodePort.put(c, 0);
      
      Iterator<Chute> auxItr = c.traverseAuxChutes();
      while (auxItr.hasNext())
      {
         Chute nextAux = auxItr.next();
         Intersection node = Intersection.factory(Kind.START_NO_BALL);
         
         board.addNode(node);
         
         chuteToFurthestNode.put(nextAux, node);
         chuteToNodePort.put(nextAux, 0);
      }
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
      
      board.addNode(node);
      
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
      if (!varToCurrentEdge.containsKey(to))
         throw new IllegalArgumentException("Variable" + to + " not present");
      
      Intersection end = Intersection.factory(Kind.END);
      board.addNode(end);
      
      Chute oldChute = varToCurrentEdge.get(to);
      
      board.addEdge(chuteToFurthestNode.get(oldChute),
            chuteToNodePort.get(oldChute), end, 0, oldChute);
      varToCurrentEdge.remove(to);
      chuteToFurthestNode.remove(oldChute);
      chuteToNodePort.remove(oldChute);
      
      Intersection newNode = Intersection.factory(from);
      board.addNode(newNode);
      
      Chute newChute = oldChute.copy();
      
      varToCurrentEdge.put(to, newChute);
      chuteToFurthestNode.put(newChute, newNode);
      chuteToNodePort.put(newChute, 0);
      
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
      board.addNode(outgoing);
      
      List<Chute> fields = levelBuilder.getFields();
      
      int currentOutPort = 0;
      for (Chute f : fields)
      {
         String fieldName = f.getName();
         Chute lastChute = varToCurrentEdge.get(fieldName);
         
         board.addEdge(chuteToFurthestNode.get(lastChute), chuteToNodePort.get(lastChute), outgoing, currentOutPort++, lastChute);
         
         Iterator<Chute> auxItr = lastChute.traverseAuxChutes();
         while(auxItr.hasNext())
         {
            Chute aux = auxItr.next();
            board.addEdge(chuteToFurthestNode.get(aux), chuteToNodePort.get(aux), outgoing, currentOutPort++, aux);
         }
      }
      
      board.deactivate();
      
      return board;
      
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
      if (c.getName() != null && varToCurrentEdge.get(c.getName()) != c)
         throw new IllegalArgumentException("add message");
      if (!chuteToFurthestNode.containsKey(c))
         throw new IllegalArgumentException("add message");
      if (!chuteToNodePort.containsKey(c))
         throw new IllegalArgumentException("c does not ");
      
      if (board.contains(n))
         throw new IllegalArgumentException("board already contains n");
      
      board.addNode(n);
      
      board.addEdge(chuteToFurthestNode.get(c), chuteToNodePort.get(c), n, inPort, c);
      
      Chute nextChute = c.copy();
      String name = nextChute.getName();
      if (name != null)
         varToCurrentEdge.put(name, nextChute);
      
      chuteToFurthestNode.remove(c);
      chuteToNodePort.remove(c);
      
      chuteToFurthestNode.put(nextChute, n);
      chuteToNodePort.put(nextChute, outPort);
   }
}
