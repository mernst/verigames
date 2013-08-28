package verigames.level;

import checkers.inference.InferenceMain;

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
   * Throws IllegalStateException if the following conditions are not met:
   *
   * Every board needs to have a unique name.
   *
   * Every subboard needs to refer to an identically named board.
   *
   * Every subboard must have the same number of input/output
   * ports as the board to which it refers.
   *
   * Every subboard's port identifiers must match those of its referent.
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
      for (Intersection isect : nodeSet)
      {
        if (isect.isSubboard())
        {
          Subboard subboard = isect.asSubboard();
          String name = subboard.getSubnetworkName();
          if (!boards.containsKey(name))
            throw new IllegalStateException("no board exists with name " + name);

          Board referent = boards.get(name);

          List<String> boardInputs  = referent.getIncomingNode().getOutputIDs();
          List<String> boardOutputs = referent.getOutgoingNode().getInputIDs();
          List<String> subboardInputs  = subboard.getInputIDs();
          List<String> subboardOutputs = subboard.getOutputIDs();

          if(InferenceMain.STRICT_MODE()) {
            if (boardInputs.size() != subboardInputs.size())
              throw new IllegalStateException("subboard " + name + " has " +
                  subboardInputs.size() + " inputs but its referent has " +
                  boardInputs.size() + " inputs");
            if (boardOutputs.size() != subboardOutputs.size())
              throw new IllegalStateException("subboard " + name + " has " +
                  subboardOutputs.size() + " outputs but its referent has " +
                  boardOutputs.size() + " outputs" + " caller: " + board.getName());

            if (!boardInputs.equals(subboardInputs))
              throw new IllegalStateException(String.format("subboard %s does " +
                  "not have the same input port identifiers as board: subboard " +
                  "has: %s, board has: %s", name, subboardInputs.toString(),
                  boardInputs.toString()));

            if (!boardOutputs.equals(subboardOutputs))
              throw new IllegalStateException(String.format("subboard %s does " +
                  "not have the same output port identifiers as board: subboard " +
                  "has: %s, board has: %s, caller: %s", name, subboardOutputs.toString(),
                  boardOutputs.toString(), board.getName()));
          }
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
