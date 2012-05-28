package verigames.level;

import java.io.PrintStream;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.Map;

/**
 * A mapping from names to {@link Level}s. Each {@code Level} must have a unique
 * name
 *
 * @author Nathaniel Mote
 *
 */

public class World
{
  private final Map<String, Level> nameToLevel;

  /**
   * Creates a new, empty {@code World}
   */
  public World()
  {
    nameToLevel = new LinkedHashMap<String, Level>();
  }

  /**
   * Adds {@code level} to {@code this}, with {@code name} as its name.
   *
   * @param level
   * The {@link Level} to add. {@link Level#underConstruction()
   * !level.underConstruction()}
   * @param name
   * The name to associate with {@code level}.
   */
  public void addLevel(String name, Level level)
  {
    if (level.underConstruction())
      throw new IllegalArgumentException(
          "underConstruction Level added to World");
    nameToLevel.put(name, level);
  }

  /**
   * Return an unmodifiable {@code Map} view on the mapping {@code this}
   * represents. The returned {@code Map} is backed by {@code this}, so changes
   * in {@code this} will be reflected in the returned {@code Map}.
   */
  public Map<String, Level> getLevels()
  {
    return Collections.unmodifiableMap(nameToLevel);
  }

  /**
   * Prints the XML for this {@code World}.
   * <p>
   * Deprecated. Instead, a {@link WorldXMLPrinter} should be used.
   * <p>
   * This method now uses a {@code WorldXMLPrinter} to do its printing.
   *
   * @param out
   * The {@code PrintStream} to which the XML will be printed. Must be open.
   */
  @Deprecated
  public void outputXML(PrintStream out)
  {
    new WorldXMLPrinter().print(this, out, null);
  }

  @Override
  public String toString()
  {
    return "World: " + getLevels().keySet().toString();
  }
}
