package graph;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.TreeMap;

import checkers.nullness.quals.Nullable;

/**
 * An immutable record type representing a node for a {@link graph.Graph
 * Graph}.
 * <p>
 * Specification Field: {@code inputs} : map from nonnegative integer to edge //
 * mapping from input port number to the edge attached at that port.
 * <p>
 * Specification Field: {@code outputs} : map from nonnegative integer to edge
 * // mapping from output port number to the edge attached at that port.
 * <p>
 * Specification Field: {@code active} : {@code boolean} // {@code true} iff
 * {@code this} can be part of a {@link graph.Graph Graph} that is still under
 * construction. Once {@code active} is set to {@code false}, {@code this}
 * becomes immutable.
 * <p>
 * Subclasses may enforce restrictions on the connections made to {@link Edge}s.
 * In particular, there may be restrictions on the number of ports particular
 * {@code Node}s have available.
 * 
 * @param <EdgeType>
 * @author Nathaniel Mote
 */

public abstract class Node<EdgeType extends Edge<? extends Node<EdgeType>>>
{
   
   // Elements are Nullable so that edges can be added in any order. Empty ports
   // are represented by null. Once the Node is deactivated, neither list can
   // contain null.
   // TODO remove warning suppression after JDK is properly annotated
   @SuppressWarnings("nullness")
   private List</* @Nullable */EdgeType> inputs;
   @SuppressWarnings("nullness")
   private List</* @Nullable */EdgeType> outputs;
   
   private boolean active = true;
   
   /*
    * Representation Invariant:
    * 
    * - if !inputs.isEmpty(), then inputs.get(inputs.size()-1) != null
    * 
    * - if !outputs.isEmpty(), then outputs.get(outputs.size()-1) != null
    * 
    * In other words, the last element in inputs and outputs must not be null
    * 
    * - If !active:
    *    - no edge in inputs or outputs may be null
    * 
    */
   
   private static final boolean CHECK_REP_ENABLED = true;
   
   /**
    * Ensures that the representation invariant holds
    */
   protected void checkRep()
   {
      if (!CHECK_REP_ENABLED)
         return;
      
      if (active)
      {
         ensure(isLastEltNonNull(inputs));
         ensure(isLastEltNonNull(outputs));
      }
      else
      {
         for (EdgeType e : inputs)
            ensure(e != null);
         for (EdgeType e : outputs)
            ensure(e != null);
      }
      
      // Note: Graph is responsible for ensuring that a particular node's
      // connections match that of the edges it is connected to (that is, the
      // edges that this is connected to must also be connected to this at the
      // appropriate ports).
      //
      // This is because there must be a point in time when the edge is
      // connected to the node, but the node is not connected to the edge, or
      // vice versa, simply because one operation must be done before the other,
      // and checkRep is called from the methods that perform those operations.
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
    * Returns {@code true} iff the last element in {@code list} is non-null, or
    * {@code list} is empty.
    * 
    * @param list
    */
   private static <E> boolean isLastEltNonNull(List<E> list)
   {
      return list.isEmpty() || list.get(list.size() - 1) != null;
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
    * <p>
    * Requires: There must not already be an {@link Edge} at the given input
    * port.
    * 
    * @param input
    * The edge to attach to {@code this} as an input. This implementation does
    * not restrict what edges may be attached, but subclasses may.
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

      // TODO check that port is nonnegative
      if (getInput(port) != null)
         throw new IllegalArgumentException("Input port at port " + port + " already used");

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
    * <p>
    * Requires: There must not already be an {@link Edge} at the given output
    * port.
    * 
    * @param output
    * The edge to attach to {@code this} as an output. This implementation does
    * not restrict what edges may be attached, but subclasses may.
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

      // TODO check that port is nonnegative
      if (getOutput(port) != null)
         throw new IllegalArgumentException("Output port at port " + port + " already used");

      padToLength(outputs, port + 1);
      outputs.set(port, output);
      checkRep();
   }
   
   /**
    * Returns the edge at the given port, or {@code null} if none exists.
    * <p>
    * @param port
    * port >= 0
    */
   public @Nullable EdgeType getInput(int port)
   {
      return get(inputs, port);
   }
   
   /**
    * Returns the edge at the given port, or {@code null} if none exists.
    * <p>
    * @param port
    * port >= 0
    */
   public @Nullable EdgeType getOutput(int port)
   {
      return get(outputs, port);
   }
   
   /**
    * Returns the element in {@code from} at {@code index}, or {@code null} if
    * none exists.
    * 
    * @param from
    * The list to query
    * @param index
    *
    * @throws IndexOutOfBoundsException
    * If index is negative.
    */
   private static <E> /*@Nullable*/ E get(List<E> from, int index)
   {
      if (index < 0)
         throw new IndexOutOfBoundsException();
      else if (index >= from.size())
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
      for (int i = 0; i < inputs.size(); i++)
      {
         EdgeType e = inputs.get(i);
         if (e == null)
            throw new IllegalStateException("Edge " + e + " at port " + i + " in inputs is null");
      }

      for (int i = 0; i < outputs.size(); i++)
      {
         EdgeType e = outputs.get(i);
         if (e == null)
            throw new IllegalStateException("Edge " + e + " at port " + i + " in outputs is null");
      }
      
      if (!active)
         throw new IllegalStateException("Deactivation attempted on already inactive Node " + this);
      active = false;
      checkRep();
   }

   /**
    * Returns a {@code String} representation of {@code this} that does not
    * include its connections to {@link Edge Edges}.
    */
   protected String shallowToString()
   {
      // by default, just return the ugly Object.toString(), because this
      // implementation doesn't have much identifying information.
      return super.toString();
   }

   @Override
   public String toString()
   {
      StringBuilder builder = new StringBuilder();
      builder.append(shallowToString() + " -- inputs: ");
      builder.append(portMapToString(getInputs()));
      builder.append(" outputs: ");
      builder.append(portMapToString(getOutputs()));
      return builder.toString();
   }

   /**
    * no null keys or values
    */
   private static <EdgeType extends Edge<?>> String portMapToString(Map<Integer, EdgeType> map)
   {
      StringBuilder builder = new StringBuilder();

      for (Map.Entry<Integer, EdgeType> entry : map.entrySet())
      {
         // auto unboxing should be fine because there should be no null keys
         int port = entry.getKey();
         EdgeType edge = entry.getValue();

         builder.append("port " + port + ": " + edge.shallowToString() + ", ");
      }

      if (builder.length() >= 2)
         builder.delete(builder.length() - 2, builder.length());

      return "[" + builder.toString() + "]";
   }
}
