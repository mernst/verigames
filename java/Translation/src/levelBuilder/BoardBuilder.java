package levelBuilder;

import level.*;

/**
 * @author Nathaniel Mote
 * 
 * A mutable class used for building a board from source code. Used to bridge
 * the gap between the Board structure and the information required by the
 * translation algorithm
 * 
 * @specfield board: Board // The board that this BoardBuilder is building
 * 
 * @specfield levelBuilder: LevelBuilder // The LevelBuilder that represents the
 * Level that "board" belongs in -- stores information global to the level that
 * is needed for construction, but not gameplay
 * 
 * @specfield varToFurthestEdge: map from Name to Chute
 * 
 * @specfield active: boolean // indicates whether this BoardBuilder represents
 * an unfinished Board
 * 
 */

public class BoardBuilder
{
	
	/**
	 * @effects creates a new BoardBuilder with the given LevelBuilder in the
	 * levelBuilder specfield
	 */
	public BoardBuilder(LevelBuilder lb)
	{
		throw new RuntimeException("Not yet implemented");
	}
}
