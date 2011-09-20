package layout;

import java.util.Collections;
import java.util.HashMap;
import java.util.Map;

import checkers.nullness.quals.AssertNonNullIfTrue;
import checkers.nullness.quals.LazyNonNull;

/**
 * An immutable class that stores information about a Graphviz graph.
 * <p>
 * All coordinates and dimensions are stored in hundredths of typographical
 * points. Points are Graphviz's default units.
 * <p>
 * Positions are given using the bottom left as the origin, with X increasing to
 * the right, and Y increasing upwards. They give the location of the center of
 * the node.
 * 
 * @author Nathaniel Mote
 */

class GraphInformation
{
   /**
    * A Builder for a GraphInformation object.
    * 
    * @author Nathaniel Mote
    */
   public static class Builder
   {
      private final Map<String, NodeAttributes> nodeAttributes;
      private @LazyNonNull GraphAttributes graphAttributes;
      
      public Builder()
      {
         nodeAttributes = new HashMap<String, NodeAttributes>();
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
      public GraphAttributes setGraphAttributes(GraphAttributes attributes)
      {
         GraphAttributes retVal = this.graphAttributes;
         
         this.graphAttributes = attributes;
         
         return retVal;
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
       * Returns a GraphInformation object with the attributes that have been added to
       * this {@code Builder}
       * <p>
       * Requires {@link #Builder.areGraphAttributesSet()}
       */
      public GraphInformation build()
      {
         if (!areGraphAttributesSet())
            throw new IllegalStateException("graph attributes not yet set");
         
         return new GraphInformation(graphAttributes, nodeAttributes);
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
      
   }
   
   private final Map<String, NodeAttributes> nodeAttributes;
   private final GraphAttributes graphAttributes;
   
   /**
    * Creates a new GraphInformation object with the given mappings from Node UID to
    * Intersection.
    * 
    */
   private GraphInformation(GraphAttributes graphAttributes,
         Map<String, NodeAttributes> nodeAttributes)
   {
      this.graphAttributes = graphAttributes;
      this.nodeAttributes = Collections
            .unmodifiableMap(new HashMap<String, NodeAttributes>(nodeAttributes));
   }
   
   /**
    * Returns the x value of the node with the given name.
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
}
