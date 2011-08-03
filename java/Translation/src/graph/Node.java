package graph;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.TreeMap;

import checkers.nullness.quals.Nullable;


public class Node<EdgeType extends Edge<? extends Node<EdgeType>>>
{
   
   // Elements are Nullable so that edgess can be added in any order. Empty
   // ports are represented by null.
   // TODO remove warning suppression after JDK is properly annotated
   @SuppressWarnings("nullness")
   private List</* @Nullable */EdgeType> inputs;
   @SuppressWarnings("nullness")
   private List</* @Nullable */EdgeType> outputs;
   
   private boolean active = true;
   
   protected void checkRep()
   {
      
   }
   
   public Node()
   {
      inputs = new ArrayList</* @Nullable */EdgeType>();
      outputs = new ArrayList</* @Nullable */EdgeType>();
   }
   
   /**
    * Sets the given edge to this Node's input at the given port,
    * replacing the old one, if present <br/>
    * <br/>
    * Requires:<br/>
    * active;<br/>
    * port is a valid port number for this Node<br/>
    * <br/>
    * Modifies: this
    * 
    */
   // TODO add clause that requires port to be nonnegative
   protected void setInput(EdgeType input, int port)
   {
      if (!active)
         throw new IllegalStateException(
               "Mutation attempted on inactive Node");
      padToLength(inputs, port + 1);
      inputs.set(port, input);
      checkRep();
   }
   
   
   /**
    * Sets the given edge to this Node's output at the given port,
    * replacing the old one, if present<br/>
    * <br/>
    * Requires:<br/>
    * active;<br/>
    * port is a valid port number for this Node <br/>
    * <br/>
    * Modifies: this
    * 
    */
   protected void setOutput(EdgeType output, int port)
   {
      if (!active)
         throw new IllegalStateException(
               "Mutation attempted on inactive Node");
      padToLength(outputs, port + 1);
      outputs.set(port, output);
      checkRep();
   }
   
   /**
    * Returns the edge at the given port, or null if none exists
    */
   public @Nullable EdgeType getInput(int port)
   {
      if (port >= inputs.size())
         return null;
      else
         return inputs.get(port);
   }
   
   /**
    * Returns the edge at the given port, or null if none exists
    */
   public @Nullable EdgeType getOutput(int port)
   {
      if (port >= outputs.size())
         return null;
      else
         return outputs.get(port);
   }
   
   /**
    * Returns Map m from port number to edge. All keys are nonnegative.
    */
   public TreeMap<Integer, EdgeType> getInputs()
   {
      TreeMap<Integer, EdgeType> toReturn = new TreeMap<Integer, EdgeType>();
      
      int index = 0;
      for (EdgeType edge : inputs)
      {
         if (edge != null)
            toReturn.put(index, edge);
         index++;
      }
      
      return toReturn;
   }
   
   /**
    * Returns Map m from port number to edge. All keys are nonnegative.
    */
   public TreeMap<Integer, EdgeType> getOutputs()
   {
      TreeMap<Integer, EdgeType> toReturn = new TreeMap<Integer, EdgeType>();
      
      int index = 0;
      for (EdgeType edge : outputs)
      {
         if (edge != null)
            toReturn.put(index, edge);
         index++;
      }
      
      return toReturn;
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
      // TODO enforce requirements for a Node to be deactivated without
      // checkRep()
      if (!active)
         throw new IllegalStateException("Mutation attempted on inactive Node");
      active = false;
      checkRep();
   }
}
