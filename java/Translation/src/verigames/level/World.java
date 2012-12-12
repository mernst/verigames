package verigames.level;

import java.util.*;

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
   * Throws IllegalStateException the subboard references aren't consistent.
   *
   * Every board needs to have a unique name.
   *
   * Every subboard needs to refer to an identically named board.
   *
   * Additionally, every subboard must have the same number of input/output
   * ports as the board to which it refers
   */
  public void validateSubboardReferences()
  {
    Map<String, Board> boards = new LinkedHashMap<String, Board>();

    // stick all the boards in the map
    for (Level level : this.getLevels().values())
    {
      for (Map.Entry<String, Board> entry : level.getBoards().entrySet())
      {
        String name = entry.getKey();
        Board board = entry.getValue();
        if (boards.containsKey(name))
          throw new IllegalStateException("duplicate board references for " + name);
        boards.put(name, board);
      }
    }

    // perform validation
    for (Board board : boards.values())
    {
      Set<Intersection> nodeSet = board.getNodes();
      for (Intersection n : nodeSet)
      {
        if (n.isSubboard())
        {
          Subboard s = n.asSubboard();
          String name = s.getSubnetworkName();
          if (!boards.containsKey(name))
            throw new IllegalStateException("no board exists with name " + name);

          Board referent = boards.get(name);

          int boardInputs = referent.getIncomingNode().getOutputIDs().size();
          int boardOutputs = referent.getOutgoingNode().getInputIDs().size();
          int subboardInputs = s.getInputIDs().size();
          int subboardOutputs = s.getOutputIDs().size();

          if (boardInputs != subboardInputs)
            throw new IllegalStateException("subboard " + name + " has " +
                subboardInputs + " inputs but its referent has " + boardInputs +
                " inputs");
          if (boardOutputs != subboardOutputs)
            throw new IllegalStateException("subboard " + name + " has " +
                subboardOutputs + " outputs but its referent has " +
                boardOutputs + " outputs");
        }
      }
    }
  }

  @Override
  public String toString()
  {
    return "World: " + getLevels().keySet().toString();
  }
}
