package level;

public class Subnetwork extends Intersection
{
   /**
    * @requires methodName stands in for a valid subnetwork
    * @effects creates a new Intersection object of type SUBNETWORK, with the
    * specific subnetwork defined by the argument
    * 
    */
   public Subnetwork(String methodName /*
                                        * String is a place-holder for whatever
                                        * we decide to use to refer to methods
                                        */)
   {
      super(Type.SUBNETWORK);
   }
   
   @Override
   protected boolean checkIntersectionType(Type type)
   {
      return type == Type.SUBNETWORK;
   }
}
