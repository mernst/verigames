import trusted.quals.*;

public class Basic {

  void bar(@Untrusted String s) {
      @Untrusted String b = s;
      @Trusted String c = "trusted";

      //:: error: (assignment.type.incompatible)
      c = s;

      //:: error: (argument.type.incompatible)      
      foo(s);

      //:: error: (argument.type.incompatible)
      foo(b);

      b = c;

      // flow refines b -> ok
      foo(b);
  }

  String foo(@Trusted String s2) {
      return s2;
  }
}
