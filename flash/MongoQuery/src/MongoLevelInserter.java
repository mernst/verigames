import java.util.ArrayList;

import com.mongodb.*;


public class MongoLevelInserter {

	static String mongoAddress = "ec2-184-72-152-11.compute-1.amazonaws.com";

	/**
	 * @param args
	 */
	public static void main(String[] args) {
		
		Mongo mongo = null;
		
        try{
            mongo = new Mongo( mongoAddress );
	        String dbName = "gameapi";
	        DB db = mongo.getDB( dbName );
	        DBCollection coll = db.getCollection("Level");
	        
	        ArrayList<DBObject> objs = new ArrayList<DBObject>();
			for(int i = 0; i<args.length; i+=2)
			{
				objs.add(createLevel(args[i], args[i+1]));
			}
			//int i = 0;
			for(int i = 0; i<objs.size(); i++)
			{
				WriteResult r1 = coll.insert(objs.get(i));
				System.out.println(r1.getLastError());
				WriteResult r2 = coll.save(objs.get(i));
				System.out.println(r2.getLastError());
			}
		       System.out.println("start");
			   DBCursor cursor = coll.find();
		        try {
		        	System.out.println(cursor.curr());
		           while(cursor.hasNext()) {
		        	   DBObject obj = cursor.next();
		        	   System.out.println(obj);
	  
		           }
		        } finally {
		           cursor.close();
		        }
		        System.out.println("end");
		        
		        DBObject obj = coll.findOne();
		        System.out.println(obj);
		        
//		        for(int i = 0; i<objs.size(); i++)
//		        {
////			coll.insert(objs.get(i));
//					coll.save(objs.get(i));
//				}
//			       System.out.println("start");
//				   DBCursor cursor1 = coll.find();
//			        try {
//			           while(cursor1.hasNext()) {
//			        	   DBObject obj = cursor1.next();
//			        	   System.out.println(obj);
//		  
//			           }
//			        } finally {
//			           cursor.close();
//			        }
//			        System.out.println("end");
		}catch(Exception e)
		{
			
		}
		finally
		{
			if(mongo != null)
				mongo.close();
		}
	}
	
	public static DBObject createLevel(String levelID, String name)
	{
		DBObject levelObj = new BasicDBObject();
		levelObj.put("levelId", levelID);
		DBObject metadataObj = new BasicDBObject();
		levelObj.put("metadata", metadataObj);

		metadataObj.put("priority", 5);
		
		DBObject paramObj = new BasicDBObject();
		paramObj.put("type", "NullChecker");
		paramObj.put("difficulty", 5);
		metadataObj.put("parameters", paramObj);
		
		DBObject propertiesObj = new BasicDBObject();
		propertiesObj.put("boxes", 10);
		propertiesObj.put("lines", 5);
		propertiesObj.put("name", name);
		metadataObj.put("properties", propertiesObj);
		
		System.out.println(levelObj);
		
		return levelObj;
	}

}
