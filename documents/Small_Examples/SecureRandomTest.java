import random.quals.*;

import java.security.SecureRandom;

public class SecureRandomTest {
	
	public static void main(String[] args) {
		java.util.Random r = new java.util.Random();
		java.util.Random r2 = new SecureRandom();

		int i = r.nextInt();    // error
		@Random int i2 = r2.nextInt();  // ok
	}
}
