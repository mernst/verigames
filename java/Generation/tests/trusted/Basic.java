import trusted.quals.*;

public class Basic {
	

  void bar(@Untrusted String s) {
      @Untrusted String b;
      @Trusted String c = "trusted";
      
      //:: error: (assignment.type.incompatible)
      c = s;


      b = c;
      
      //:: error: (argument.type.incompatible)      
      foo(s);

      //:: error: (argument.type.incompatible)
      foo(b);
  }
  
  String foo(@Trusted String s2) {
	  return s2;
  }
}
