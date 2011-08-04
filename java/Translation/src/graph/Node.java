package graph;

import java.util.ArrayList;
import java.util.List;
import java.util.TreeMap;

import checkers.nullness.quals.Nullable;

/**
 * A mutable node for {@link Graph.graph Graph}.<br/>
 * <br/>
 * Specification Field: {@code inputs} : map from nonnegative integer to edge //
 * mapping from input port number to the edge attached at that port.<br/>
 * <br/>
 * Specification Field: {@code outputs} : map from nonnegative integer to edge
 * // mapping from output port number to the edge attached at that port.<br/>
 * <br/>
 * Specification Field: {@code active} : {@code boolean} // {@code true} iff
 * {@code this} can be part of a {@link graph.Graph Graph} that is still under
 * construction. once {@code active} is set to {@code false}, {@code this}
 * becomes immutable.
 * 
 * @param <EdgeType>
 * @author Nathaniel Mote
 */

public class Node<EdgeType extends Edge<? extends Node<EdgeType>>>
{
   
   // Elements are Nullable so that edges can be added in any order. Empty
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
    * Adds the given edge to {@code inputs} with the given port number.<br/>
    * <br/>
    * Requires:<br/>
    * - {@code this.isActive()}<br/>
    * <br/>
    * Modifies: {@code this}
    * 
    * @param input
    * The edge to attach to {@code this} as an input.
    * @param port
    * The input port to which {@code input} will be attached. Must be
    * nonnegative. Must be a valid port number for {@code this}. This
    * implementation enforces no restrictions on what ports are valid (other
    * than that they must be nonnegative), but subclasses may.<br/>
    */
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
    * Adds the given edge to {@code outputs} with the given port number.<br/>
    * <br/>
    * Requires:<br/>
    * - {@code this.isActive()}<br/>
    * <br/>
    * Modifies: {@code this}
    * 
    * @param output
    * The edge to attach to {@code this} as an output.
    * @param port
    * The output port to which {@code output} will be attached. Must be
    * nonnegative. Must be a valid port number for {@code this}. This
    * implementation enforces no restrictions on what ports are valid (other
    * than that they must be nonnegative), but subclasses may.<br/>
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
    * Returns the edge at the given port, or {@code null} if none exists
    */
   public @Nullable EdgeType getInput(int port)
   {
      return get(inputs, port);
   }
   
   /**
    * Returns the edge at the given port, or {@code null} if none exists
    */
   public @Nullable EdgeType getOutput(int port)
   {
      return get(outputs, port);
   }
   
   /**
    * Returns the element in {@code from} at {@code index}, or {@code null} if
    * none exists
    * 
    * @param from
    * The list to query
    * @param index
    */
   private static <E> /*@Nullable*/ E get(List<E> from, int index)
   {
      if (index >= from.size())
         return null;
      else
         return from.get(index);
   }
   
   /**
    * Returns a {@code TreeMap<Integer, EdgeType> m} from port number to input
    * edge. All keys are nonnegative. {@code m} and {@code this} will not be
    * affected by future changes to each other.
    */
   public TreeMap<Integer, EdgeType> getInputs()
   {
      return getMapFromList(inputs);
   }
   
   /**
    * Returns a {@code TreeMap<Integer, EdgeType> m} from port number to output
    * edge. All keys are nonnegative. {@code m} and {@code this} will not be
    * affected by future changes to each other.
    */
   public TreeMap<Integer, EdgeType> getOutputs()
   {
      return getMapFromList(outputs);
   }
   
   /**
    * Returns a {@code TreeMap<Integer, E>} from indices to non-null elements.
    * No index that would map to a null element is included.
    * 
    * @param list
    * The {@code List} from which to create the returned {@code Map}
    */
   private static <E> TreeMap<Integer, E> getMapFromList(List<E> list)
   {
      TreeMap<Integer, E> toReturn = new TreeMap<Integer, E>();
      
      int index = 0;
      for (E edge : list)
      {
         if (edge != null)
            toReturn.put(index, edge);
         index++;
      }
      
      return toReturn;
   }
   
   /**
    * Ensures that {@code list.size() >= length} by padding {@code list} with
    * {@code null}<br/>
    * <br/>
    * Modifies: {@code list}
    * 
    * @param list
    * the {@code List} to pad
    * @param length
    * the minimum length that {@code list} is guaranteed to have after this
    * method exits
    */
   // TODO change after JDK is properly annotated
   @SuppressWarnings("nullness")
   private static <E> void padToLength(List</* @Nullable */E> list, int length)
   {
      while (list.size() < length)
         list.add(null);
   }
   
   /**
    * Returns {@code active}
    */
   public boolean isActive()
   {
      return active;
   }
   
   /**
    * Sets {@code active} to {@code false}<br/>
    * <br/>
    * Requires:<br/>
    * - {@code this.isActive()}<br/>
    * - There are no empty ports. That is, for the highest filled port (for both
    * inputs and outputs), there are no empty ports below it.<br/>
    * - Other implementations may enforce additional restrictions on the number
    * of input or output ports that must be filled when deactivated.
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
