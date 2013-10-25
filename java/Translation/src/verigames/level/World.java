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
    Map<String, StubBoard> stubBoards = new LinkedHashMap<String, StubBoard>();

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

      for( Map.Entry<String, StubBoard> entry : level.getStubBoards().entrySet() ) {
          String name = entry.getKey();
          StubBoard stubs = entry.getValue();
          if (stubBoards.containsKey(name)) {
              throw new IllegalStateException("duplicate stubboard references for " + name);
          }

          stubBoards.put(name, stubs);
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
          final boolean isBoard     = boards.containsKey( name );
          final boolean isStubBoard = stubBoards.containsKey( name );

          if ( !isBoard && !isStubBoard )
            throw new IllegalStateException("no board or stub board exists with name " + name);

          if( isBoard ) {
              validateReferenceToBoard( board, subboard, boards );
          } else {
              validateReferenceToStubBoard( board, subboard, stubBoards );
          }

        }
      }
    }
  }

 /**
  * Expected = board or stub board
  * actual   = subboard
  * @param subboardName
  * @param boardName
  * @param expectedInputs
  * @param expectedOutputs
  * @param actualInputs
  * @param actualOutputs
  * @return
  */
  private void checkReferences( final String subboardName, final String boardName,
                                final List<String> expectedInputs,
                                final List<String> expectedOutputs,
                                final List<String> actualInputs,
                                final List<String> actualOutputs) {
     if( verigames.utilities.Misc.CHECK_REP_STRICT ) {
       if (expectedInputs.size() != actualInputs.size())
         throw new IllegalStateException("subboard " + subboardName + " has " +
                                         actualInputs.size() + " inputs but its referent has " +
                                         expectedInputs.size() + " inputs");
       if (expectedOutputs.size() != actualOutputs.size())
         throw new IllegalStateException("subboard " + subboardName + " has " +
                 actualOutputs.size() + " outputs but its referent has " +
                 expectedOutputs.size() + " outputs" + " caller: " + boardName );

       if (!expectedInputs.equals(actualInputs))
         throw new IllegalStateException(String.format("subboard %s does " +
                 "not have the same input port identifiers as board: subboard " +
                 "has: %s, board has: %s", subboardName, actualInputs.toString(),
                 expectedInputs.toString()));

       if (!expectedOutputs.equals(actualOutputs))
         throw new IllegalStateException(String.format("subboard %s does " +
                 "not have the same output port identifiers as board: subboard " +
                 "has: %s, board has: %s, caller: %s", subboardName, actualOutputs.toString(),
                 expectedOutputs.toString(), boardName));
     }
  }

  private void validateReferenceToBoard(final Board currentBoard, final Subboard subboard, final Map<String, Board> boards ) {
      String name = subboard.getSubnetworkName();

      Board referent = boards.get(name);

      checkReferences( name,  referent.getName(),
                       referent.getIncomingNode().getOutputIDs(), referent.getOutgoingNode().getInputIDs(),
                       subboard.getInputIDs(), subboard.getOutputIDs() );
  }

  private void validateReferenceToStubBoard(final Board currentBoard, final Subboard subboard, final Map<String, StubBoard> stubBoards ) {
      String name = subboard.getSubnetworkName();

      StubBoard referent = stubBoards.get(name);
      List<String> referentInputs  = referent.getInputIDs();
      List<String> referentOutputs = referent.getOutputIDs();

      //Id's are stored in a TreeMap in Intersections and therefore come out in alphabetical order
      Collections.sort( referentInputs  );
      Collections.sort( referentOutputs );

      checkReferences( name,  name,
                       referentInputs, referentOutputs,
                       subboard.getInputIDs(), subboard.getOutputIDs() );
  }

  @Override
  public String toString()
  {
    return "World: " + getLevels().keySet().toString();
  }
}
