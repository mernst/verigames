package verigames.level;

import java.io.*;
import java.util.*;

import nu.xom.*;

import verigames.utilities.Pair;

/**
 * An object that parses verigames XML documents and returns a corresponding
 * object representation in the form of a {@link World}.
 *
 * @author Nathaniel Mote
 */
public class WorldXMLParser
{
  public static final int version = 1;

  /**
   * Parses the text from {@code in} as XML, and returns a {@link World} object
   * representing the same information.
   * <p>
   * The elements in the returned {@code World} are not under construction
   * (meaning that no structural mutation is allowed). This is because the
   * {@link Board} graphs cannot currently have nodes or edges removed, and it
   * is unlikely that any other structural modification would be useful. There
   * is the possibility that {@link Level}s may benefit from having {@code
   * Board}s added to them, but currently, there is no reason to do so.
   */
  /* This method should perhaps be static, but it is left as nonstatic so that
   * it is consistent with WorldXMLPrinter, whose print method is nonstatic
   * to facilitate code reuse (it's a subclass of Printer) */
  public World parse(final InputStream in)
  {
    // creates a Builder that validates the input;
    final Builder parser = new Builder(true);

    final Document doc;
    
    try
    {
      doc = parser.build(in);
    }
    catch (ValidityException e)
    {
      throw new RuntimeException("Document does not validate", e);
    }
    catch (ParsingException e)
    {
      throw new RuntimeException("Document poorly formed", e);
    }
    catch (IOException e)
    {
      throw new RuntimeException("Could not read document", e);
    }

    final Element root = doc.getRootElement();

    return processWorld(root);
  }

  private static World processWorld(final Element worldElt)
  {
    checkName(worldElt, "world");

    // check version
    {
      Attribute versionAttr = worldElt.getAttribute("version");
      int XMLVersion = Integer.parseInt(versionAttr.getValue());

      if (XMLVersion != version)
        throw new IllegalArgumentException("Parser expected version " + version
            +" but XML is version " + XMLVersion);
    }

    final World w = new World();

    final Elements children = worldElt.getChildElements();

    for (int i = 0; i < children.size(); i++)
    {
      final Element child = children.get(i);
      final Pair<String, Level> p = processLevel(child);
      String name = p.getFirst();
      Level level = p.getSecond();
      level.finishConstruction();
      w.addLevel(name, level);
    }

    return w;
  }

  private static Pair<String, Level> processLevel(final Element levelElt)
  {
    checkName(levelElt, "level");

    final Level level = new Level();

    final String name;
    {
      Attribute nameAttr = levelElt.getAttribute("name");
      name = nameAttr.getValue();
    }
    
    /* the boards must be processed first because Level requires that edges
     * already be present before makeLinked is called with them as arguments.*/
    final Pair<Map<String, Board>, Map<String, Chute>> p = processBoards(levelElt.getFirstChildElement("boards"));
    final Map<String, Board> boards = p.getFirst();
    final Map<String, Chute> chuteUIDs = p.getSecond();

    for (Map.Entry<String, Board> entry : boards.entrySet())
    {
      final String boardName = entry.getKey();
      final Board board = entry.getValue();

      level.addBoard(boardName, board);
    }

    final Set<Set<String>> linkedEdges;
    {
      Element linkedEdgesElt = levelElt.getFirstChildElement("linked-edges");
      linkedEdges = processLinkedEdges(linkedEdgesElt);
    }

    for (Set<String> UIDSet : linkedEdges)
    {
      Set<Chute> chutes = new LinkedHashSet<Chute>();
      for (String UID : UIDSet)
        chutes.add(chuteUIDs.get(UID));
      level.makeLinked(chutes);
    }
      
    return Pair.of(name, level);
  }

  private static Set<Set<String>> processLinkedEdges(final Element linkedEdgesElt)
  {
    checkName(linkedEdgesElt, "linked-edges");

    final Set<Set<String>> linkedEdgeSets = new LinkedHashSet<Set<String>>();

    final Elements edgeSetElts = linkedEdgesElt.getChildElements();

    for (int i = 0; i < edgeSetElts.size(); i++)
    {
      final Element edgeSetElt = edgeSetElts.get(i);
      final Set<String> edgeSet = processEdgeSet(edgeSetElt);
      linkedEdgeSets.add(edgeSet);
    }

    return Collections.unmodifiableSet(linkedEdgeSets);
  }

  private static Set<String> processEdgeSet(Element edgeSetElt)
  {
    checkName(edgeSetElt, "edge-set");

    final Set<String> edges = new LinkedHashSet<String>();

    final Elements edgerefElts = edgeSetElt.getChildElements();

    for (int i = 0; i < edgerefElts.size(); i++)
    {
      final Element edgerefElt = edgerefElts.get(i);
      final String edgeUID = processEdgeref(edgerefElt);
      edges.add(edgeUID);
    }

    return Collections.unmodifiableSet(edges);
  }

  private static String processEdgeref(final Element edgerefElt)
  {
    checkName(edgerefElt, "edgeref");
    
    final Attribute idAttr = edgerefElt.getAttribute("id");
    return idAttr.getValue();
  }

  /**
   * Returns a map from {@link Board} names to {@code Board}s and a map from
   * {@link Chute} UIDs to {@code Chute}s.
   */
  private static Pair<Map<String, Board>, Map<String, Chute>> processBoards(final Element boards)
  {
    checkName(boards, "boards");

    final Map<String, Board> boardsMap = new LinkedHashMap<String, Board>();
    final Map<String, Chute> chuteUIDs = new LinkedHashMap<String, Chute>();

    final Elements children = boards.getChildElements();

    for (int i = 0; i < children.size(); i++)
    {
      final Element child = children.get(i);
      final Pair<Pair<String, Board>, Map<String, Chute>> p = processBoard(child);
      final Pair<String, Board> boardInfo = p.getFirst();
      final Map<String, Chute> boardChuteUIDs = p.getSecond();

      boardsMap.put(boardInfo.getFirst(), boardInfo.getSecond());
      chuteUIDs.putAll(boardChuteUIDs);
    }

    return Pair.of(
            Collections.unmodifiableMap(boardsMap),
            Collections.unmodifiableMap(chuteUIDs));
  }

  // TODO make sure to document this monster return type
  private static Pair<Pair<String, Board>, Map<String, Chute>> processBoard(final Element boardElt)
  {
    checkName(boardElt, "board");
    
    final String name;
    {
      final Attribute nameAttr = boardElt.getAttribute("name");
      name = nameAttr.getValue();
    }

    final Board b = new Board();

    final Elements nodesElts = boardElt.getChildElements("node");
    final Elements edgesElts = boardElt.getChildElements("edge");

    /* map the XML UIDs of the nodes to Intersection objects. Object UIDs are
     * almost certainly going to be different from those in the XML, so we need
     * to keep track of which Intersections the XML is referring to in order to
     * attach edges (which refer to XML UIDs) later. */
    final Map<String, Intersection> UIDMap = processNodes(nodesElts);

    for (Intersection n : UIDMap.values())
    {
      if (n.getIntersectionKind() == Intersection.Kind.INCOMING)
        b.addNode(n);
    }

    if (b.getIncomingNode() == null)
      throw new RuntimeException("No INCOMING node found");

    for (Intersection n : UIDMap.values())
    {
      if (n != b.getIncomingNode())
        b.addNode(n);
    }

    if (b.getOutgoingNode() == null)
      throw new RuntimeException("No OUTGOING node found");

    Map<String, Chute> ChuteUIDMap = processEdges(edgesElts, b, UIDMap);

    return Pair.of(
            Pair.of(name, b),
            Collections.unmodifiableMap(ChuteUIDMap));
  }

  /**
   *
   */
  private static Map<String, Intersection> processNodes(final Elements nodeElts)
  {
    final Map<String, Intersection> UIDMap = new LinkedHashMap<String, Intersection>();

    for (int i = 0; i < nodeElts.size(); i++)
    {
      final Element nodeElt = nodeElts.get(i);
      final Pair<String, Intersection> result = processNode(nodeElt);
      final String name = result.getFirst();
      final Intersection intersection = result.getSecond();

      UIDMap.put(name, intersection);
    }

    return Collections.unmodifiableMap(UIDMap);
  }

  private static Pair<String, Intersection> processNode(final Element nodeElt)
  {
    checkName(nodeElt, "node");

    final Intersection.Kind kind;
    try
    {
      final Attribute kindAttr = nodeElt.getAttribute("kind");
      kind = Enum.valueOf(Intersection.Kind.class, kindAttr.getValue());
    }
    catch (IllegalArgumentException e)
    {
      throw new RuntimeException("Illegal Intersection Kind used", e);
    }

    final String UID;
    {
      final Attribute UIDAttr = nodeElt.getAttribute("id");
      UID = UIDAttr.getValue();
    }

    final /*@Nullable*/ Double x;
    final /*@Nullable*/ Double y;
    {
      final Element layoutElt = nodeElt.getFirstChildElement("layout");
      if (layoutElt == null)
      {
        x = null;
        y = null;
      }
      else
      {
        final Pair<Double, Double> result = processLayoutPoint(layoutElt);
        x = result.getFirst();
        y = result.getSecond();
      }
    }

    /* Edge connections are intentionally not processed -- the data is
     * redundant, and it's simpler to get it when we're processing the edges. */

    final Intersection intersection;
    switch (kind)
    {
      case SUBBOARD:
        final Attribute nameAttr = nodeElt.getAttribute("name");
        if (nameAttr == null)
          throw new RuntimeException("Subboard node does not have a name attribute");
        final String name = nameAttr.getValue();
        intersection = Intersection.subboardFactory(name);
        break;
      default:
        intersection = Intersection.factory(kind);
    }

    if (x != null)
    {
      /* These errors really should not happen -- validation should catch it,
       * and if it doesn't, an error would probably occur earlier. These are
       * just in case there's a serious problem with this code. */
      if (y == null)
        throw new RuntimeException("x coordinate encountered with no corresponding y coordinate");
      intersection.setX(x);
      intersection.setY(y);
    }
    else if (y != null)
      throw new RuntimeException("y coordinate encountered with no corresponding x coordinate");

    return Pair.of(UID, intersection);
  }

  private static Pair<Double, Double> processLayoutPoint(Element layoutElt)
  {
    {
      final String eltName = layoutElt.getLocalName();
      if (!(eltName.equals("layout") || eltName.equals("point")))
        throw new RuntimeException("Encountered " + eltName + " when point or layout was expected");
    }
    
    final double x;
    {
      final Element xElt = layoutElt.getFirstChildElement("x");
      x = processCoordinate(xElt);
    }

    final double y;
    {
      final Element yElt = layoutElt.getFirstChildElement("y");
      y = processCoordinate(yElt);
    }

    return Pair.of(x,y);
  }

  private static double processCoordinate(Element coordElt)
  {
    {
      final String eltName = coordElt.getLocalName();
      if (!(eltName.equals("x") || eltName.equals("y")))
        throw new RuntimeException("Encountered " + eltName + " when x or y was expected");
    }

    try
    {
      return Double.parseDouble(coordElt.getValue());
    }
    catch (NumberFormatException e)
    {
      throw new RuntimeException("malformed coordinate", e);
    }
  }

  /**
   * Modifies {@code b}
   */
  private static Map<String, Chute> processEdges(final Elements edgeElts, final Board b, final Map<String, Intersection> IntersectionUIDMap)
  {
    final Map<String, Chute> ChuteUIDMap = new LinkedHashMap<String, Chute>();

    for (int i = 0; i < edgeElts.size(); i++)
    {
      final Element edgeElt = edgeElts.get(i);
      final Pair<String, Chute> p = processEdge(edgeElt, b, IntersectionUIDMap);
      final String UID = p.getFirst();
      final Chute c = p.getSecond();
      ChuteUIDMap.put(UID, c);
    }

    return Collections.unmodifiableMap(ChuteUIDMap);
  }

  /**
   * Modifies {@code b}
   */
  private static Pair<String, Chute> processEdge(final Element edgeElt, final Board b, final Map<String, Intersection> UIDMap)
  {
    checkName(edgeElt, "edge");

    final String description;
    {
      final Attribute descriptionAttr = edgeElt.getAttribute("description");
      description = descriptionAttr.getValue();
    }

    final int variableID;
    try
    {
      final Attribute variableIDAttr = edgeElt.getAttribute("variableID");
      variableID = Integer.parseInt(variableIDAttr.getValue());
    }
    catch (NumberFormatException e)
    {
      throw new RuntimeException("edge variableID attribute contains noninteger data", e);
    }

    final boolean pinch;
    {
      final Attribute pinchAttr = edgeElt.getAttribute("pinch");
      pinch = Boolean.parseBoolean(pinchAttr.getValue());
    }

    final boolean narrow;
    {
      final Attribute widthAttr = edgeElt.getAttribute("width");
      narrow = widthAttr.getValue().equals("narrow");
    }

    final boolean editable;
    {
      final Attribute editableAttr = edgeElt.getAttribute("editable");
      editable = Boolean.parseBoolean(editableAttr.getValue());
    }

    final boolean buzzsaw;
    {
      final Attribute buzzsawAttr = edgeElt.getAttribute("buzzsaw");
      buzzsaw = Boolean.parseBoolean(buzzsawAttr.getValue());
    }

    final String UID;
    {
      final Attribute UIDAttr = edgeElt.getAttribute("id");
      UID = UIDAttr.getValue();
    }

    final List<Pair<Double, Double>> layout;
    {
      final Element layoutElt = edgeElt.getFirstChildElement("edge-layout");
      if (layoutElt == null)
        layout = null;
      else
        layout = processEdgeLayout(layoutElt);
    }

    // pair of XML UID for an Intersection and port
    final Pair<String, Integer> startID;
    {
      final Element fromElt = edgeElt.getFirstChildElement("from");
      final Element noderefElt = fromElt.getFirstChildElement("noderef");
      startID = processNodeRef(noderefElt);
    }

    final Pair<String, Integer> endID;
    {
      final Element toElt = edgeElt.getFirstChildElement("to");
      final Element noderefElt = toElt.getFirstChildElement("noderef");
      endID = processNodeRef(noderefElt);
    }

    final Intersection start = UIDMap.get(startID.getFirst());
    final int startPort = startID.getSecond();

    final Intersection end = UIDMap.get(endID.getFirst());
    final int endPort = endID.getSecond();

    final Chute c = new Chute(variableID, description);
    c.setPinched(pinch);
    c.setNarrow(narrow);
    c.setEditable(editable);
    c.setBuzzsaw(buzzsaw);
    if (layout != null)
      c.setLayout(layout);
    
    b.addEdge(start, startPort, end, endPort, c);

    return Pair.of(UID, c);
  }

  private static Pair<String, Integer> processNodeRef(Element nodeRef)
  {
    checkName(nodeRef, "noderef");

    final String ID;
    {
      final Attribute IDAttr = nodeRef.getAttribute("id");
      ID = IDAttr.getValue();
    }

    final int port;
    try
    {
      final Attribute portAttr = nodeRef.getAttribute("port");
      port = Integer.parseInt(portAttr.getValue());
    }
    catch (NumberFormatException e)
    {
      throw new RuntimeException("port attribute of noderef did not contain an integer", e);
    }
    
    return Pair.of(ID, port);
  }

  private static List<Pair<Double, Double>> processEdgeLayout(Element layoutElt)
  {
    checkName(layoutElt, "edge-layout");

    final List<Pair<Double, Double>> result = new ArrayList<Pair<Double, Double>>();

    final Elements pointElts = layoutElt.getChildElements();

    for (int i = 0; i < pointElts.size(); i++)
    {
      Element pointElt = pointElts.get(i);
      Pair<Double, Double> point = processLayoutPoint(pointElt);
      result.add(point);
    }

    return result;
  }

  /**
   * @throws RuntimeException
   * if elt.getLocalName() does not equal the expected name.<br/>
   * Else has no effect.
   */
  private static void checkName(Element elt, String expectedName)
  {
    if (!elt.getLocalName().equals(expectedName))
      throw new RuntimeException("Encountered " + elt.getLocalName() + " when " + expectedName + " was expected");
  }
}
