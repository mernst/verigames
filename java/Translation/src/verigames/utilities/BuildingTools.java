package verigames.utilities;

import static verigames.level.Intersection.factory;

import java.util.Map;

import verigames.level.Board;
import verigames.level.Chute;
import verigames.level.Intersection;
import verigames.level.Level;
import verigames.level.Intersection.Kind;


/**
 * A set of tools used to automate repetitive tasks when building {@link
 * verigames.level.World World}s, {@link verigames.level.Level Level}s, and {@link verigames.level.Board
 * Board}s.
 */
// This shouldn't really be part of the public API -- it's basically just
// often-repeated code that's been extracted into static methods, rather than
// methods that perform specific tasks, and as such, it's not very clear, and is
// unlikely to be useful to clients. However, it can't be package-private
// because code in multiple packages uses it.
public class BuildingTools
{
  
  /**
   * Makes a new Board, adds it to level with the given name, and adds incoming
   * and outgoing nodes to it.
   * <p>
   * Modifies: {@code level}
   *
   * @param level
   */
  public static Board initializeBoard(Level level, String name)
  {
    Board b = new Board();
    level.addBoard(name, b);
    
    b.addNode(Intersection.factory(Kind.INCOMING));
    b.addNode(Intersection.factory(Kind.OUTGOING));
    
    return b;
  }
  
  /**
   * Adds a field of the given name to the given {@link verigames.level.Board Board}.
   */
  public static void addField(Board b, Map<String, Chute> fieldToChute, Map<String, Integer> nameToPortMap, String name, Kind kind)
  {
    Intersection start = factory(kind);
    b.addNode(start);
    
    Chute chute = new Chute();
    b.addEdge(start, 0, b.getOutgoingNode(), nameToPortMap.get(name), chute);
    b.addChuteName(chute, name);
    fieldToChute.put(name, chute);
  }
  
  public static void connectFields(Board b, Level level, Map<String, Chute> fieldToChute, Map<String, Integer> nameToPort, String... fieldNames)
  {  
    for (String name : fieldNames)
      connectField(b, nameToPort.get(name), name, level, fieldToChute);
  }
  
  private static void connectField(Board b, int port, String name, Level level, Map<String, Chute> fieldToChute)
  {
    Chute newChute = fieldToChute.get(name).copy();
    
    b.addEdge(b.getIncomingNode(), port, b.getOutgoingNode(), port, newChute);
    b.addChuteName(newChute, name);
    
    level.makeLinked(fieldToChute.get(name), newChute);
  }
}
