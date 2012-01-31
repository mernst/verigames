package verigames.level;

/**
 * A class used to run the suite of specification tests for the level objects
 * 
 * @author Nathaniel Mote
 * 
 */

import org.junit.runner.RunWith;
import org.junit.runners.Suite;
import org.junit.runners.Suite.SuiteClasses;

@RunWith(Suite.class)
@SuiteClasses({ ChuteSpecTests.class, BoardSpecTests.class,
		IntersectionSpecTests.class, NullTestSpecTests.class,
		LevelSpecTests.class, LevelXMLTests.class })
public class SpecificationTests {
	// Placeholder class
}