import trusted.quals.*;

public class Basic {

  void bar() {
      @Untrusted String b = "untrusted";
      @Trusted String c = "trusted";
      
      //:: error: (assignment.type.incompatible)
      c = b;
      
      b = c;
  }
}
