package graph;

import java.util.ArrayList;
import java.util.List;

import checkers.nullness.quals.Nullable;


public class Node<EdgeType extends Edge<? extends Node<EdgeType>>>
{
   
   // Elements are Nullable so that chutes can be added in any order. Empty
   // ports are represented by null.
   // TODO remove warning suppression after JDK is properly annotated
   @SuppressWarnings("nullness")
   protected List</* @Nullable */EdgeType> inputChutes;
   @SuppressWarnings("nullness")
   protected List</* @Nullable */EdgeType> outputChutes;
   
   private boolean active = true;
   
   protected void checkRep()
   {
      
   }
   
   public Node()
   {
      inputChutes = new ArrayList</* @Nullable */EdgeType>();
      outputChutes = new ArrayList</* @Nullable */EdgeType>();
   }
   
   /**
    * Sets the given chute to this Node's input at the given port,
    * replacing the old one, if present <br/>
    * <br/>
    * Requires:<br/>
    * active;<br/>
    * port is a valid port number for this Node<br/>
    * <br/>
    * Modifies: this
    * 
    */
   // TODO refactor to remove reference to Chute
   protected void setInputChute(EdgeType input, int port)
   {
      if (!active)
         throw new IllegalStateException(
               "Mutation attempted on inactive Node");
      padToLength(inputChutes, port + 1);
      inputChutes.set(port, input);
      checkRep();
   }
   
   
   /**
    * Sets the given chute to this Node's output at the given port,
    * replacing the old one, if present<br/>
    * <br/>
    * Requires:<br/>
    * active;<br/>
    * port is a valid port number for this Node <br/>
    * <br/>
    * Modifies: this
    * 
    */
   protected void setOutputChute(EdgeType output, int port)
   {
      if (!active)
         throw new IllegalStateException(
               "Mutation attempted on inactive Node");
      padToLength(outputChutes, port + 1);
      outputChutes.set(port, output);
      checkRep();
   }
   
   /**
    * Returns the chute at the given port, or null if none exists
    */
   public @Nullable EdgeType getInputChute(int port)
   {
      if (port >= inputChutes.size())
         return null;
      else
         return inputChutes.get(port);
   }
   
   /**
    * Returns the chute at the given port, or null if none exists
    */
   public @Nullable EdgeType getOutputChute(int port)
   {
      if (port >= outputChutes.size())
         return null;
      else
         return outputChutes.get(port);
   }
   
   /**
    * Ensures that list.size() >= length by padding the list with null<br/>
    * <br/>
    * Modifies: list
    * 
    * @param list
    * the List to pad
    * @param length
    * the minimum length that list is guaranteed to have after this method exits
    */
   // TODO change after JDK is properly annotated
   @SuppressWarnings("nullness")
   private static <E> void padToLength(List</* @Nullable */E> list, int length)
   {
      while (list.size() < length)
         list.add(null);
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
    * Requires:<br/>active;<br/>all ports for this Kind of Node are filled
    */
   protected void deactivate()
   {
      // TODO enforce requirements for an Node to be deactivated without
      // checkRep()
      if (!active)
         throw new IllegalStateException("Mutation attempted on inactive Node");
      active = false;
      checkRep();
   }
}
