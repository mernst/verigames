import java.util.*;

public class MethodGenericsLocalCall {
	public <T> void genericMethodNoReturn(T t1) {
	}

	public void localCall() {
		this.<String>genericMethodNoReturn("test");
	}	
}

