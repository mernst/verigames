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

      concat(s);

      b = c;

      // flow refines b -> ok
      foo(b);      
  }
 
  void concat(String s) {
	  String a = "trusted";
	  String b = "trusted";
	  
	  @Trusted String safe = a + b;
	  
	  //:: error: (assignment.type.incompatible)
	  @Trusted String unsafe = a + s;
  }

  String foo(@Trusted String s2) {
      return s2;
  }
}
