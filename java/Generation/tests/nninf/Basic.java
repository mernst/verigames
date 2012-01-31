import nninf.quals.*;

public class Basic {
  @Nullable Basic b;

  void m() {
      //:: error: (receiver.null)
      b.m();
      
      b = new Basic();
      b.m();
      
      //:: error: (receiver.null)
      b.m();
      
      //:: error: (receiver.null)
      b.b = null;
  }
  
  void bar() {
      @NonNull Basic b = null;
      
      if (4 != 9) {
          b = new Basic();
          b.m();
      }
      
      //:: error: (receiver.null)
      b.m();
      
      if (b!=null) {
          b.m();
      }
  }
}
