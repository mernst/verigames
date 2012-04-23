import nninf.quals.*;

public class Basic {
  @Nullable Basic b;

  void m() {
      //:: error: (dereference.of.nullable)
      b.m();

      b = new Basic();
      // TODO: creates an error without flow
      //:: error: (dereference.of.nullable)
      b.m();

      //:: error: (dereference.of.nullable)
      b.m();

      //:: error: (dereference.of.nullable)
      b.b = null;
  }

  void bar() {
      //:: error: (assignment.type.incompatible)
      @NonNull Basic b = null;

      if (4 != 9) {
          b = new Basic();
          b.m();
      }

      // OK, b is declared NonNull
      b.m();

      if (b!=null) {
          b.m();
      }
  }

}
