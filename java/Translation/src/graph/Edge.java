package graph;

import checkers.nullness.quals.AssertNonNullAfter;
import checkers.nullness.quals.LazyNonNull;
import checkers.nullness.quals.Nullable;

public class Edge<NodeType extends Node<? extends Edge<NodeType>>>
{
   private @LazyNonNull NodeType start;
   private int startPort = -1;
   private @LazyNonNull NodeType end;
   private int endPort = -1;

   private boolean active = true;
   
   private static final boolean CHECK_REP_ENABLED = true;
   
   protected void checkRep()
   {
      if (CHECK_REP_ENABLED)
      {
         if (!active)
         {
            ensure(start != null);
            ensure(end != null);
            ensure(startPort != -1);
            ensure(endPort != -1);
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
    * Returns start, or null if end does not exist
    */
   public @Nullable NodeType getStart()
   {
      return start;
   }
   
   /**
    * Returns startPort<br/>
    * <br/>
    * Requires:<br/>
    * this chute has a "start" intersection
    */
   public int getStartPort()
   {
      if (start == null)
         throw new IllegalStateException();
      return startPort;
   }
   
   /**
    * Returns end, or null if end does not exist
    */
   public @Nullable NodeType getEnd()
   {
      return end;
   }
   
   /**
    * Returns endPort<br/>
    * <br/>
    * Requires:<br/>
    * this chute has an "end" intersection
    */
   public int getEndPort()
   {
      if (end == null)
         throw new IllegalStateException();
      return endPort;
   }
   
   /**
    * Requires: start != null; port is a valid port number for start Modifies:
    * this sets "start" to the given Intersection, replacing the old one, if
    * present
    */
   @AssertNonNullAfter({ "start" }) protected void setStart(NodeType start,
         int port)
   {
      if (!active)
         throw new IllegalStateException("Mutation attempted on inactive Chute");
      if (start == null)
         throw new IllegalArgumentException(
               "Chute.setStart passed a null argument");
      
      this.start = start;
      this.startPort = port;
      checkRep();
   }
   
   /**
    * Requires: start != null; port is a valid port number for start Modifies:
    * this sets "end" to the given Intersection, replacing the old one, if
    * present
    */
   @AssertNonNullAfter({ "end" }) protected void setEnd(NodeType end,
         int port)
   {
      if (!active)
         throw new IllegalStateException("Mutation attempted on inactive Chute");
      if (end == null)
         throw new IllegalArgumentException(
               "Chute.setEnd passed a null argument");
      
      this.end = end;
      this.endPort = port;
      checkRep();
   }
   
   /**
    * Returns active
    */
   public boolean isActive()
   {
      return active;
   }
   
   /**
    * Sets active to false<br/>
    * <br/>
    * Requires:<br/>active;<br/>start and end Intersections exist
    */
   protected void deactivate()
   {
      if (!active)
         throw new IllegalStateException("Mutation attempted on inactive Chute");
      active = false;
      checkRep();
   }
}
