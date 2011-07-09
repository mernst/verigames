package level.tests;

import org.junit.runner.RunWith;
import org.junit.runners.Suite;
import org.junit.runners.Suite.SuiteClasses;

/**
 * 
 * A class used to run the suite of implementation tests for the level objects
 * 
 * @author Nathaniel Mote
 * 
 */

@RunWith(Suite.class)
@SuiteClasses({ IntersectionImpTests.class, BoardImpTests.class,
		ChuteImpTests.class, NullTestImpTests.class })
public class ImplementationTests {
	// Placeholder class
}
