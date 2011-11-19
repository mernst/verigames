package layout;

import static utilities.Misc.ensure;

import utilities.Pair;

import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import checkers.nullness.quals.AssertNonNullIfTrue;
import checkers.nullness.quals.LazyNonNull;
import checkers.nullness.quals.Nullable;

/**
 * An immutable class that stores information about a Graphviz graph.
 * <p>
 * All coordinates and dimensions are stored in hundredths of typographical
 * points. Points are Graphviz's default units.
 * <p>
 * Positions are given using the bottom left as the origin, with X increasing to
 * the right, and Y increasing upwards. They give the location of the center of
 * the node.
 * <p>
 * In an undirected graph, the directionality of an edge is meaningless --
 * however, even in undirected graphs, Graphviz picks one node to be the start
 * of an edge, and this structure reflects this decision. Therefore, when
 * accessing the edges of an undirected graph, it is prudent to check both
 * directions.
 * 
 * @author Nathaniel Mote
 */

class GraphInformation
{
   private final GraphAttributes graphAttributes;
   private final Map<String, NodeAttributes> nodeAttributes;
   private final Map<Pair<String, String>, EdgeAttributes> edgeAttributes;
   
   /**
    * Creates a new GraphInformation object with the given mappings from Node UID to
    * Intersection.
    * 
    */
   private GraphInformation(GraphAttributes graphAttributes,
         Map<String, NodeAttributes> nodeAttributes, Map<Pair<String, String>, EdgeAttributes> edgeAttributes)
   {
      this.graphAttributes = graphAttributes;

      this.nodeAttributes = Collections
            .unmodifiableMap(new HashMap<String, NodeAttributes>(nodeAttributes));

      this.edgeAttributes = Collections.unmodifiableMap(
            new HashMap<Pair<String, String>, EdgeAttributes>(edgeAttributes));
   }
   
   /**
    * Returns the attributes of the node with the given name.
    * 
    * @param name
    * {@link #containsNode(String) containsNode(name)} must be true.
    */
   public NodeAttributes getNodeAttributes(String name)
   {
      if (!this.containsNode(name))
         throw new IllegalArgumentException("!this.containsNode(" + name + ")");
      
      return nodeAttributes.get(name);
   }
   
   /**
    * Returns the attributes of the graph itself
    */
   public GraphAttributes getGraphAttributes()
   {
      return graphAttributes;
   }

   /**
    * Returns the attributes of the given edge
    * <p>
    * this must contain an edge from startNode to endNode
    * equivalently, 
    *
    * @param startNode
    * @param endNode
    */
   public EdgeAttributes getEdgeAttributes(String startNode, String endNode)
   {
      if (!this.containsEdge(startNode, endNode))
         throw new IllegalArgumentException("No edge from \"" + startNode +
               "\" to \"" + endNode + "\"");

      return edgeAttributes.get(new Pair<String, String>(startNode, endNode));
   }
   
   /**
    * Returns {@code true} iff {@code this} contains attributes for a node of
    * the given name
    * 
    * @param name
    */
   public boolean containsNode(String name)
   {
      return nodeAttributes.containsKey(name);
   }

   /**
    * Returns {@code true} iff {@code this} contians an edge from {@code
    * startNode} to {@code endNode}
    * 
    * @param startNode
    * @param endNode
    */
   public boolean containsEdge(String startNode, String endNode)
   {
      return edgeAttributes.containsKey(new Pair<String, String>(startNode,
            endNode));
   }
   
   /**
    * Returns {@code true} iff {@code this} and {@code other} are equal in
    * value.
    */
   @Override
   public boolean equals(Object other)
   {
      if (other instanceof GraphInformation)
      {
         GraphInformation g = (GraphInformation) other;
         
         return this.getGraphAttributes().equals(g.getGraphAttributes())
               && this.nodeAttributes.equals(g.nodeAttributes);
      }
      else
      {
         return false;
      }
   }
   
   @Override
   public int hashCode()
   {
      return graphAttributes.hashCode() * 31 + nodeAttributes.hashCode();
   }

   @Override
   public String toString()
   {
      return "graph:" + graphAttributes.toString() + ";nodes:" +
            nodeAttributes.toString();
   }
   
   /**
    * A Builder for a GraphInformation object.
    * 
    * @author Nathaniel Mote
    */
   public static class Builder
   {
      private @LazyNonNull GraphAttributes graphAttributes;
      private final Map<String, NodeAttributes> nodeAttributes;
      private final Map<Pair<String, String>, EdgeAttributes> edgeAttributes;
      
      public Builder()
      {
         nodeAttributes = new HashMap<String, NodeAttributes>();
         edgeAttributes = new HashMap<Pair<String, String>, EdgeAttributes>();
         graphAttributes = null;
      }
      
      /**
       * Sets the properties of this graph to those defined by
       * {@code attributes}.
       * <p>
       * 
       * @return the previous GraphAttributes object, or null if none existed
       */

      // This may need to be changed somehow because graph attributes can be
      // split across multiple lines in DOT. Maybe a way to merge them or
      // something?
      public @Nullable GraphAttributes setGraphAttributes(GraphAttributes attributes)
      {
         GraphAttributes oldAttrs = this.graphAttributes;
         
         this.graphAttributes = attributes;
         
         return oldAttrs;
      }
      
      /**
       * Returns true iff the graph attributes have been set
       */
      @AssertNonNullIfTrue("graphAttributes")
      public boolean areGraphAttributesSet()
      {
         return graphAttributes != null;
      }
      
      /**
       * Sets the attributes associated with the node with the given name.
       */
      public void setNodeAttributes(String name, NodeAttributes attributes)
      {
         nodeAttributes.put(name, attributes);
      }

      /**
       * Sets the attributes associated with the edge from {@code startNode} to
       * {@code endNode}
       *
       * @param startNode
       * The ID of the starting node for this edge.
       * @param endNode
       * The ID of the ending node for this edge.
       */
      public void setEdgeAttributes(String startNode, String endNode, EdgeAttributes attributes)
      {
         edgeAttributes.put(new Pair<String, String>(startNode, endNode), attributes);
      }
      
      /**
       * Returns a GraphInformation object with the attributes that have been added to
       * this {@code Builder}
       * <p>
       * Requires {@link Builder#areGraphAttributesSet()}
       */
      public GraphInformation build()
      {
         if (!areGraphAttributesSet())
            throw new IllegalStateException("graph attributes not yet set");
         
         return new GraphInformation(graphAttributes, nodeAttributes, edgeAttributes);
      }
   }
   
   /**
    * An immutable record type that stores the width and the height of a
    * Graphviz graph in hundredths of points
    */
   public static class GraphAttributes
   {
      private final int width;
      private final int height;
      
      public GraphAttributes(int width, int height)
      {
         this.width = width;
         this.height = height;
      }
      
      /**
       * Returns the width of the graph.
       */
      public int getWidth()
      {
         return width;
      }
      
      /**
       * Returns the height of the graph.
       */
      public int getHeight()
      {
         return height;
      }
      
      @Override
      public boolean equals(Object other)
      {
         if (other instanceof GraphAttributes)
         {
            GraphAttributes g = (GraphAttributes) other;
            
            return this.getHeight() == g.getHeight()
                  && this.getWidth() == g.getWidth();
         }
         else
         {
            return false;
         }
      }

      @Override
      public int hashCode()
      {
         return width * 97 + height;
      }

      @Override
      public String toString()
      {
         return "width=" + getWidth() + ";height=" + getHeight();
      }
   }
   
   /**
    * An immutable record type containing attributes of a particular node
    */
   public static class NodeAttributes
   {
      private final int x;
      private final int y;
      private final int width;
      private final int height;
      
      public NodeAttributes(int x, int y, int width, int height)
      {
         this.x = x;
         this.y = y;
         this.width = width;
         this.height = height;
      }
      
      /**
       * Returns the x coordinate of the center of this node, in hundredths of points.
       */
      public int getX()
      {
         return x;
      }
      
      /**
       * Returns the y coordinate of the center of this node, in hundredths of points.
       */
      public int getY()
      {
         return y;
      }
      
      /**
       * Returns the width of this node, in hundredths of points.
       */
      public int getWidth()
      {
         return width;
      }
      
      /**
       * Returns the height of this node, in hundredths of points.
       */
      public int getHeight()
      {
         return height;
      }
      
      @Override
      public boolean equals(Object other)
      {
         if (other instanceof NodeAttributes)
         {
            NodeAttributes g = (NodeAttributes) other;
            
            return this.getX() == g.getX() && this.getY() == g.getY()
                  && this.getHeight() == g.getHeight()
                  && this.getWidth() == g.getWidth();
         }
         else
         {
            return false;
         }
      }

      @Override
      public int hashCode()
      {
         int hashCode = getX();
         hashCode *= 31;
         hashCode += getY();
         hashCode *= 31;
         hashCode += getWidth();
         hashCode *= 31;
         hashCode += getHeight();
         return hashCode;
      }

      @Override
      public String toString()
      {
         return "pos=(" + getX() + "," + getY() + ");width=" + getWidth() +
               ";height=" + getHeight();
      }
   }

   public static class EdgeAttributes
   {
      /**
       * Stores the control points for the spline. Should be instantiated as an
       * immutable list.
       * <p>
       * Must have length congruent to 1 (mod 3), as enforced by Graphviz.
       */
      private final List<Point> controlPoints;

      private void checkRep()
      {
         ensure(controlPoints.size() % 3 == 1);
      }

      /**
       * Constructs a new {@code EdgeAttributes} object.
       * <p>
       * @param points
       * The control points for this edge's b-spline. {@code points.size() % 3}
       * must equal {@code 1}.
       */
      public EdgeAttributes(List<Point> points)
      {
         if (points.size() % 3 != 1)
            throw new IllegalArgumentException("Size of argument is " +
                  points.size() + ". " + points.size() + " % 3 = " +
                  (points.size() % 3) + " != 1");

         // Creates a new list containing the elements in points, where the only
         // view on it is an unmodifiable view. In effect, make it immutable.
         this.controlPoints = Collections.unmodifiableList(new ArrayList<Point>(points));

         checkRep();
      }

      public Point getPoint(int index)
      {
         checkBounds(index);
         return controlPoints.get(index);
      }

      public int getX(int index)
      {
         checkBounds(index);
         return controlPoints.get(index).getX();
      }

      public int getY(int index)
      {
         checkBounds(index);
         return controlPoints.get(index).getY();
      }

      private void checkBounds(int index)
      {
         if (index >= controlPoints.size())
            throw new IndexOutOfBoundsException("index " + index + " >= size ("
                  + controlPoints.size() + ")");
      }

      public int size()
      {
         return controlPoints.size();
      }
   }

   /**
    * A record type representing a 2D point.
    * <p>
    * Stores integer x and y values that are values in hundredths of points.
    */
   public static class Point
   {
      private final int x;
      private final int y;

      public Point(int x, int y)
      {
         this.x = x;
         this.y = y;
      }

      public int getY()
      {
         return y;
      }

      public int getX()
      {
         return x;
      }
   }
}
