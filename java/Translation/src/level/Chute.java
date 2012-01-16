package level;

import utilities.Pair;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;


/**
 * A mutable chute segment for use in a {@link Board}. Once {@link #underConstruction()
 * this.underConstruction()} is false, {@code this} is immutable.<br/>
 * <br/>
 * Implements eternal equality because it is mutable, but must be used in
 * {@code Collection}s<br/>
 * <br/>
 * Specification Field: {@code pinch} : {@code boolean} // {@code true} iff
 * there is a pinch-point in this chute segment<br/>
 * {@code false} by default.<br/>
 * <br/>
 * Specification Field: {@code narrow} : {@code boolean} // {@code true} iff the
 * chute is currently narrow<br/>
 * <br/>
 * Specification Field: {@code editable} : {@code boolean} // {@code true} iff
 * the player can edit the width of the chute<br/>
 * <br/>
 * Specification Field: Layout Coordinates : list of (x: real, y:real), where
 * the length of the list is 3n + 1, where n is a nonnegative integer. // The
 * coordinates for the B-spline defining this edge's curve.<br/>
 * <br/>
 * Specification Field: {@code UID} : integer // the unique identifier for this
 * chute<br/>
 * <br/>
 * Except in corner cases, {@code pinch} --> {@code narrow}. This is not,
 * however, enforced.<br/>
 * 
 * @author Nathaniel Mote
 */

public class Chute extends graph.Edge<Intersection>
{
   private boolean pinch;
   
   private boolean narrow;
   private boolean editable;

   // should be instantiated as an immutable list
   // TODO enforce length in checkRep
   private /*@Nullable*/ List<Pair<Double, Double>> layout;
   
   private final int UID;
   
   private static int nextUID = 1;
   
   /**
    * Creates a new {@code Chute} object.
    */
   public Chute()
   {
      this.editable = true;
      
      this.narrow = false;
      this.pinch = false;
      
      this.UID = Chute.nextUID;
      Chute.nextUID += 1;

      this.checkRep();
   }
   
   /**
    * Returns {@code pinch}<br/>
    * <br/>
    * Defaults to {@code false}
    */
   public boolean isPinched()
   {
      return pinch;
   }
   
   /**
    * Sets {@code pinch} to the value of the parameter<br/>
    * <br/>
    * Requires: {@link #underConstruction() this.underConstruction()}<br/>
    * <br/>
    * Modifies: {@code this}
    * 
    * @param pinched
    */
   public void setPinched(boolean pinched)
   {
      if (!underConstruction())
         throw new IllegalStateException("Mutation attempted on constructed Chute");
      this.pinch = pinched;
      checkRep();
   }
   
   /**
    * Returns {@code narrow}
    */
   public boolean isNarrow()
   {
      return narrow;
   }
   
   /**
    * Sets the specification field {@code narrow} to the value of the parameter
    * {@code narrow}<br/>
    * <br/>
    * Requires: {@link #underConstruction() this.underConstruction()}<br/>
    * <br/>
    * Modifies: {@code this}
    * 
    * @param narrow
    */
   public void setNarrow(boolean narrow)
   {
      if (!underConstruction())
         throw new IllegalStateException("Mutation attempted on constructed Chute");
      this.narrow = narrow;
      checkRep();
   }
   
   /**
    * Returns {@code editable}
    */
   public boolean isEditable()
   {
      return editable;
   }
   
   /**
    * Sets the specification field {@code editable} to the value of the
    * parameter {@code editable}<br/>
    * <br/>
    * Requires: {@link #underConstruction() this.underConstruction()}<br/>
    * <br/>
    * Modifies: {@code this}
    * 
    * @param editable
    */
   public void setEditable(boolean editable)
   {
      if (!underConstruction())
         throw new IllegalStateException("Mutation attempted on constructed Chute");
      
      this.editable = editable;
      checkRep();
   }

   public void setLayout(List<Pair<Double, Double>> layout)
   {
      if (layout.size() < 4 || layout.size() % 3 != 1)
         throw new IllegalArgumentException("Number of points (" +
            layout.size() +
            ") illegal -- must be of the form 3n + 1 where n is a positive integer");

      this.layout = Collections.unmodifiableList(
            new ArrayList<Pair<Double,Double>>(layout));
   }

   public /*@Nullable*/ List<Pair<Double, Double>> getLayout()
   {
      return this.layout;
   }
   
   /**
    * Returns {@code UID}
    */
   public int getUID()
   {
      return UID;
   }
   
   /**
    * Returns a deep copy of {@code this}.
    * <p>
    * If this chute has {@code start} or {@code end} nodes, that information
    * will not be copied.
    * <p>
    * The choice not to override {@code Object.clone()} was deliberate. {@code
    * copy()} intentionally only copies *some* of the properties of a {@code
    * Chute}, and, notably, leaves out the UID. The UID is (and should be) a
    * final field, and if {@code clone()} were used, the UID would need to be
    * modified after object creation in order to maintain the property that no
    * two {@code Chute}s have the same UID.
    */
   // TODO explicitly document which information is and is not copied.
   public Chute copy()
   {
      Chute copy = new Chute();
      copy.setNarrow(narrow);
      copy.setPinched(pinch);
      copy.setEditable(editable);
      
      return copy;
   }

   @Override
   protected String shallowToString()
   {
      String propertyString = isNarrow() ? "Narrow" : "Wide";

      if (isPinched())
         propertyString += ", Pinched";

      return "Chute#" + getUID() + " (" + propertyString + ")";
   }
}
