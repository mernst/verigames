package verigames.optimizer;

import org.testng.annotations.BeforeClass;
import org.testng.annotations.Test;
import verigames.level.Board;
import verigames.level.Chute;
import verigames.level.Level;
import verigames.level.RandomWorldGenerator;
import verigames.level.World;
import verigames.optimizer.model.MismatchException;
import verigames.optimizer.model.ReverseMapping;

import java.util.ArrayList;
import java.util.Collection;
import java.util.Random;

/**
 * Tests various invariants of the optimizer.
 * In particular:
 * <ul>
 *     <li>the resulting world should be strictly smaller</li>
 *     <li>the resulting world should be a valid world</li>
 * </ul>
 */
@Test
public class OptimizerTest {

    Collection<World> worlds;

    @BeforeClass
    public void setup() {
        final int NUM_WORLDS = 10;
        final int RANDOM_SEED = 33; // arbitrary, but consistent from run to run

        worlds = new ArrayList<>(NUM_WORLDS);
        Random random = new Random(RANDOM_SEED);
        RandomWorldGenerator gen = new RandomWorldGenerator(random);
        for (int i = 0; i < NUM_WORLDS; ++i) {
            worlds.add(gen.randomWorld());
        }
    }

    @Test
    public void worldIsValid() {
        Optimizer optimizer = new Optimizer();
        for (World world1 : worlds) {
            World world2 = optimizer.optimizeWorld(world1, new ReverseMapping());
            world2.validateSubboardReferences();
        }
    }

    @Test
    public void mappingIsValid() throws MismatchException {
        Optimizer optimizer = new Optimizer();
        for (World world1 : worlds) {
            ReverseMapping mapping = new ReverseMapping();
            World world2 = optimizer.optimizeWorld(world1, mapping);
            mapping.apply(world1, world2); // no exceptions should be thrown

            // only mutable chutes should be mapped
            for (Chute c : world1.getChutes()) {
                if (mapping.map(c.getVariableID()) != null) {
                    assert c.isEditable();
                }
            }

        }
    }

    @Test
    public void worldIsSmaller() {
        Optimizer optimizer = new Optimizer();

        for (World world1 : worlds) {

            int numLevels1 = world1.getLevels().size();
            int numBoards1 = 0;
            int numNodes1 = 0;
            int numEdges1 = 0;
            for (Level level : world1.getLevels().values()) {
                for (Board board : level.getBoards().values()) {
                    ++numBoards1;
                    numNodes1 += board.getNodes().size();
                    numEdges1 += board.getEdges().size();
                }
            }

            World world2 = optimizer.optimizeWorld(world1, new ReverseMapping());

            int numLevels2 = world2.getLevels().size();
            int numBoards2 = 0;
            int numNodes2 = 0;
            int numEdges2 = 0;
            for (Level level : world2.getLevels().values()) {
                for (Board board : level.getBoards().values()) {
                    ++numBoards2;
                    numNodes2 += board.getNodes().size();
                    numEdges2 += board.getEdges().size();
                }
            }

            assert numLevels2 <= numLevels1;
            assert numBoards2 <= numBoards1;
            assert numNodes2 <= numNodes1;
            assert numEdges2 <= numEdges1;

        }
    }

}
