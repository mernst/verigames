import encrypted.quals.*;

public class Basic {

  void bar(@Plaintext String s, @Encrypted String c) {
      @Plaintext String b = s;

      //:: error: (assignment.type.incompatible)
//      c = s;

      //:: error: (argument.type.incompatible)      
//      foo(s);

      //:: error: (argument.type.incompatible)
//      foo(b);

      concat(s, c, c);

      b = c;

      // flow refines b -> ok
      foo(b);      
      
      TestInterface interf = new TestClass();

      //:: error: (argument.type.incompatible)      
//      interf.myMethod(s);
      
//      interf.myMethod(b);
  }

  void concat(String s, @Encrypted String a, @Encrypted String b) {

      @Encrypted String safe = a + b;

      //:: error: (assignment.type.incompatible)
      //@Encrypted String unsafe = a + s;
  }

  String foo(@Encrypted String s2) {
      return s2;
  }
  

  interface TestInterface {
	  public void myMethod(@Encrypted String s);
  }

  class TestClass implements TestInterface {
	  public void myMethod(String s) {
		  return;
	  }
  }
}
