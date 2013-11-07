package verigames.optimizer.model;

import org.testng.annotations.Test;
import verigames.level.Board;
import verigames.level.Chute;
import verigames.level.Intersection;
import verigames.level.Level;
import verigames.level.World;
import verigames.optimizer.Util;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;

public class ReverseMappingTest {

    @Test
    public void testIO() throws IOException {
        ReverseMapping mapping = new ReverseMapping();
        mapping.forceNarrow(1);
        mapping.forceWide(2);
        mapping.mapEdge(3, 4);
        mapping.mapEdge(6, 7);

        ByteArrayOutputStream output = new ByteArrayOutputStream();
        mapping.export(output);

        ReverseMapping mapping2 = ReverseMapping.load(new ByteArrayInputStream(output.toByteArray()));

        assert mapping.equals(mapping2);
    }

}
