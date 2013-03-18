import hardcoded.quals.*;

public class HardCodedTest {

	public static void main(String[] args) {
		String hash = (@NotHardCoded String) "hashedpassword";
		method(hash); 			// ok
		method("monkey123");		// error
		method(hash + "monkey123"); 	//error
	}

	public static void method(@NotHardCoded String password) {
		
	}
}
