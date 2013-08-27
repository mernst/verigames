import java.io.File;

import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;

import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;

import com.mongodb.*;


public class MongoLevelInserter {

	static String mongoAddress = "ec2-184-72-152-11.compute-1.amazonaws.com";

	DB db = null;
	DBCollection levelColl = null;
	DBCollection layoutColl = null;
	Document difficultyRatings;

	/**
	 * @param args
	 */
	public static void main(String[] args) {
		
		Mongo mongo = null;
		DB db = null;
		
		if(args.length < 3)
		{
			System.out.println("Usage: (this app, whatever it's called) mongoFileID raLevelID LevelName");
			return;
		}
        try{
			mongo = new Mongo( mongoAddress );
	        String dbName = "gameapi";
	        db = mongo.getDB( dbName );
//			parentIDList.add("51815bcfa8e027680cbd21b1");
//			nameList.add("Seth's Level");
//			
//			parentIDList.add("51815bc3a8e027680cbd21ab");
//			nameList.add("Simple Level");
			
	        MongoLevelInserter inserter = new MongoLevelInserter(db, new File(args[3]));
	        
	        inserter.addLevel(args[0], args[1], args[2]);
	      
		}catch(Exception e)
		{
			
		}
		finally
		{

		}
	}
	
	public MongoLevelInserter(DB _db, File difficultyFile)
	{
		db = _db;
	    levelColl = db.getCollection("Level");
	    layoutColl = db.getCollection("SubmittedLayouts");
	    if(difficultyFile != null)
	    {
	    	try{
	    	DocumentBuilderFactory dbFactory = DocumentBuilderFactory.newInstance();
	    	DocumentBuilder dBuilder = dbFactory.newDocumentBuilder();
	    	difficultyRatings = dBuilder.parse(difficultyFile);
	    	}
	    	catch(Exception e)
	    	{
	    		
	    	}
	    }
	    
	}
	
	public boolean isValid()
	{
		if(levelColl != null)
			return true;
		else
			return false;
	}
	
	public void addLevel(String levelID, String xmlID, String levelName)
	{
 		DBObject levelobj = createLevelObject(levelID, xmlID, xmlID, xmlID, levelName);
		WriteResult r1 = levelColl.insert(levelobj);
		System.out.println(r1.getLastError());
		
		DBObject layoutobj = createLayoutObject(levelID, xmlID, xmlID, xmlID, levelName);
		r1 = layoutColl.insert(layoutobj);
		System.out.println(r1.getLastError());
	}
	
	public void addLevel(String levelID, MongoFileInserter inserter, String levelName)
	{
 		DBObject obj = createLevelObject(levelID, inserter, levelName);
		WriteResult r1 = levelColl.insert(obj);
		System.out.println(r1.getLastError());
		
		DBObject layoutobj = createLayoutObject(levelID, inserter, levelName);
		r1 = layoutColl.insert(layoutobj);
		System.out.println(r1.getLastError());
	}
	
	public DBObject createLevelObject(String levelID, MongoFileInserter inserter, String name)
	{
		return createLevelObject(levelID, inserter.xmlID, inserter.layoutID, inserter.constraintsID, name);
	}
	
	//NOTE:levelId needs to stay named that (and be unique), as DB will throw error without
	public DBObject createLevelObject(String levelID, String xmlID, String layoutID, String constraintsID, String name)
	{
		System.out.println( levelID+" " +xmlID+" " +layoutID+" " +constraintsID+" " +name);
		int numBoxes = 5;
		int numEdges = 5;
		int numConflicts = 0;
		int numVisibleBoxes = 5;
		int numVisibleEdges = 5;
		int numBonusNodes = 5;
		//find the levelID in the difficulty ratings, if it exists
		if(difficultyRatings != null)
		{
			NodeList nList = difficultyRatings.getElementsByTagName("file");
			for(int i = 0; i<nList.getLength(); i++)
			{
				Node node = nList.item(i);
				Element element = (Element) node;
				String nodeName = element.getAttribute("name");
				if(nodeName.equals(name))
				{
					numBoxes = Integer.parseInt(element.getAttribute("nodes"));
					numEdges = Integer.parseInt(element.getAttribute("edges"));
					numConflicts = Integer.parseInt(element.getAttribute("conflicts"));
					numVisibleBoxes = Integer.parseInt(element.getAttribute("visible_nodes"));
					numVisibleEdges = Integer.parseInt(element.getAttribute("visible_edges"));
					numBonusNodes = Integer.parseInt(element.getAttribute("bonus_nodes"));
				}
			}
		}
		DBObject levelObj = new BasicDBObject();
		levelObj.put("levelId", levelID);
		levelObj.put("rootlevelId", levelID);
		levelObj.put("xmlID", xmlID);
		levelObj.put("layoutID", layoutID);
		levelObj.put("constraintsID", constraintsID);
		levelObj.put("name", name);
		DBObject metadataObj = new BasicDBObject();
		levelObj.put("metadata", metadataObj);

		metadataObj.put("priority", 5);
		
		DBObject paramObj = new BasicDBObject();
		paramObj.put("type", 0.0);
		paramObj.put("difficulty", 5.0);
		metadataObj.put("parameters", paramObj);
		
		DBObject propertiesObj = new BasicDBObject();
		propertiesObj.put("boxes", numBoxes);
		propertiesObj.put("lines", numEdges);
		propertiesObj.put("visibleboxes", numVisibleBoxes);
		propertiesObj.put("visiblelines", numVisibleEdges);
		propertiesObj.put("conflicts", numConflicts);
		propertiesObj.put("bonus_nodes", numBonusNodes);
		metadataObj.put("properties", propertiesObj);
		
		System.out.println(levelObj);
		
		return levelObj;
	}

	public DBObject createLayoutObject(String levelID, MongoFileInserter inserter, String name)
	{
		return createLayoutObject(levelID, inserter.xmlID, inserter.layoutID, inserter.constraintsID, name);
	}
	
	//NOTE:levelId needs to stay named that (and be unique), as DB will throw error without
	public DBObject createLayoutObject(String levelID, String xmlID, String layoutID, String constraintsID, String name)
	{
		DBObject layoutObj = new BasicDBObject();
		layoutObj.put("name", "Starter Layout");
        layoutObj.put("levelId", levelID);
        layoutObj.put("layoutID", layoutID);
		layoutObj.put("xmlID", xmlID+"L");
		
		System.out.println(layoutObj);
		
		return layoutObj;
	}

}