package layout.tests;

import org.junit.Test;
import static org.junit.Assert.*;

import layout.GraphInformation;
import static layout.GraphInformation.*;

public class GraphInformationSpecTests
{
   @Test
   public void graphAttributesEqualsTest()
   {
      GraphAttributes g1 = new GraphAttributes(348, 283);
      GraphAttributes g2 = new GraphAttributes(348, 283);
      assertEquals(g1, g2);
   }
   
   @Test
   public void nodeAttributesEqualsTest()
   {
      NodeAttributes n1 = new NodeAttributes(232, 46924, 22435, 2345);
      NodeAttributes n2 = new NodeAttributes(232, 46924, 22435, 2345);
      assertEquals(n1, n2);
   }

   @Test
   public void graphInformationEqualsTest()
   {
      Builder b = new Builder();
   }
}
