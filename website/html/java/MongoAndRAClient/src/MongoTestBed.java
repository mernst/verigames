import com.mongodb.*;
import com.mongodb.gridfs.*;

import java.io.BufferedReader;
import java.io.Console;
import java.io.FileOutputStream;
import java.io.FilenameFilter;
import java.io.File;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.PrintWriter;
import java.util.Dictionary;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

import org.bson.types.ObjectId;

public class MongoTestBed {

//    public static byte[] LoadFile(String filePath) throws Exception {
//        File file = new File(filePath);
//        int size = (int)file.length();
//        byte[] buffer = new byte[size];
//        FileInputStream in = new FileInputStream(file);
//        in.read(buffer);
//        in.close();
//        return buffer;
//    }

    private static final boolean removeLevels = false;

	public static void main(String[] args) throws Exception {


        //staging game level server
       //    Mongo mongo = new Mongo( "api.flowjam.verigames.com" );
     Mongo mongo = new Mongo( "api.paradox.verigames.com", 27017 );
      //  staging RA server
     //  Mongo mongo = new Mongo( "ec2-23-22-125-169.compute-1.amazonaws.com" );
        String dbName = "game3api";
        DB db = mongo.getDB( dbName );
        //Create GridFS object
        GridFS fs = new GridFS( db );
     //    listEntries(db, "GameSolvedLevels");

        listCollectionNames(db);
       HashMap<String, String> map = new HashMap();
       map.put("playerID", "");
  //     map.put("levelID", "12");
       listEntries(db, "GameSolvedLevels", map, true);
     //    listLog(db);
 //         saveAndCleanLog(db, "old");
        
	    mongo.close();
	}
	
	static void listEntries(DB db, String collectionName)
	{
		listEntries(db, collectionName, null, false);
	}
	
	static void listEntries(DB db, String collectionName, HashMap<String, String> searchKeys, boolean remove)
	{
		//PrintWriter writer = null;
    	DBCursor cursor = null;
    	try 
    	{
    		//writer = new PrintWriter("Entries.txt", "UTF-8");

        	   
        	  
		BasicDBObject field = new BasicDBObject();
		if(searchKeys != null)
		for (Map.Entry<String, String> entry : searchKeys.entrySet()) {
		    String key = entry.getKey();
		    String value = entry.getValue();
		    field.put(key, value);
		}
		
		DBCollection collection = db.getCollection(collectionName);
//		 try { 
			 cursor = collection.find(field);
			 while(cursor.hasNext()) {
           	DBObject obj = cursor.next();
               System.out.println(obj);
        //       writer.println(obj);
               if(remove)
            	   collection.remove(obj);
           }
    	}catch (Exception e)
    	{
    		
        } finally {
        	if(cursor != null)
        		cursor.close();
        }
    	
    	// writer.close();
			
		
	}
        
 //       db.createCollection("SavedLevels", null);
  //      DBCollection foo = db.getCollection("SubmittedLevels");
   //     db.createCollection("SubmittedLayouts", null);
        //Save image into database
        
//        if(args.length == 1)
//        {
//	        File file = new File(args[0]);
//	        if(file.isDirectory())
//	        {
//	        	File[] files = file.listFiles(new FilenameFilter() {
//	        	    public boolean accept(File directory, String fileName) {
//	        	        return fileName.endsWith(".zip") 
//	        	        && !fileName.endsWith("Graph.zip") 
//	        	        && !fileName.endsWith("Constraints.zip");
//	        	    }});
//	        	
//	        	for(int i=0; i<files.length; i++)
//	        	{
//	        		File xmlFile = files[i];
//	        		GridFSInputFile xmlin = fs.createFile( xmlFile );
//	        		 String fileName = xmlFile.getName();
//	        		 int index = fileName.lastIndexOf('.');
//	        		 fileName = fileName.substring(0, index);
//	     	        xmlin.put("name", fileName);
//	     	        xmlin.save();
//	     	        
//	     	        String filePath = xmlFile.getPath();
//	     	        //remove xml, and add gxl extension
//	     	       int baseIndex = filePath.lastIndexOf('.');
//	     	        String filebase = filePath.substring(0, baseIndex);
//	     	        File graphFile = new File(filebase+"Graph.zip");
//	     	        //Save image into database
//	     	        GridFSInputFile gxlin = fs.createFile( graphFile );
//	     	        gxlin.setMetaData(new BasicDBObject("name", fileName+" Starter Layout"));
//	     	        gxlin.setMetaData(new BasicDBObject("xmlID", xmlin.getId()));
//	     	        gxlin.save();
//	     	        
//	     	        File constraintsFile = new File(filebase+"Constraints.zip");
//	     	        //Save image into database
//	     	        GridFSInputFile conin = fs.createFile( constraintsFile );
//	     	        conin.setMetaData(new BasicDBObject("name", fileName+" Starter Constraints"));
//	     	        conin.setMetaData(new BasicDBObject("xmlID", xmlin.getId()));
//	     	        conin.save();
//	        	}
//	        }
//        }
//        else
//        {
//	        File xmlFile = new File(args[0]+"\\"+args[1]+".xml");
//	        GridFSInputFile xmlin = fs.createFile( xmlFile );
//	        xmlin.put("name", args[1]);
//	        xmlin.save();
//	        
//	        File gxlFile = new File(args[0]+"\\"+args[1]+".gxl");
//	          //Save image into database
//	        GridFSInputFile gxlin = fs.createFile( gxlFile );
//	        gxlin.setMetaData(new BasicDBObject("xmlID", xmlin.getId()));
//	        gxlin.save();
//        }
       
        //Find saved image
       
      //save the a file
//        File install = new File(args[0]+"\\"+args[1]+".xml");		
//        GridFSInputFile inFile =  fs.createFile(install);
//        inFile.save();
      	
        //read the file
//        ObjectId id = new ObjectId("51881753a8e0d2ea01b9afd7");
//     //   BasicDBObject obj = new BasicDBObject("metadata.xmlID", id);
//        GridFSDBFile outFile = fs.findOne(id);
//        System.out.println(outFile.get("name"));
//        outFile.put("name", "test");
//    
//        System.out.println("");//xmlin.getID() " + xmlin.getId());
//        
//      		
//        //write output to temp file
 //       File temp = new File("C:\\Users\\craigc\\Documents\\Pipejam\\flash\\PipeJam3\\SampleWorlds\\DemoWorld\\test\\delme.tmp");
//        outFile.writeTo(temp);
        
//        BasicDBObject field = new BasicDBObject();
//        field.put("xmlID", "515b0fa84942d3ddc997bdc6");
////        
//        
//        GridFSDBFile objList1 = fs.findOne("Application1.xml");
//     //   for(int i = 0; i<objList1.size(); i++)
//        {
//        	System.out.println(objList1.toString());
//        }
        
//        DBCursor cursor1 = fs.getFileList();
//        try { 
//            while(cursor1.hasNext()) {
//            	DBObject obj = cursor1.next();
//                System.out.println(obj);
//                if(removeLevels)
//                	fs.remove(obj);
//            }
//         } finally {
//            cursor1.close();
//         }
    
//	
//	    //Save loaded image from database into new image file
//	    FileOutputStream outputImage = new FileOutputStream(args[0] + "\\bearCopy1.gxl");
//	    out.writeTo( outputImage );
//	    outputImage.close();
//	    
//	    System.out.println(xmlin.getId() + " " + gxlin.getId());
	
	static void findObjects(DB db, String objectID, String collectionName)
	{
//	        Set<String> colls = db.getCollectionNames();
//
//	        int count = 0;
//	        for (String s : colls) {
//
//	            System.out.println("Collection " + s);
//	            if(s.equals("log"))
//	            {
//	            	PrintWriter writer = new PrintWriter(s+"930.txt", "UTF-8");
//		            DBCollection coll = db.getCollection(s);
//		            ObjectId field = new ObjectId(objectID);
//		           // field.put("$oid", "51ed5bb9a8e0be024c017fa2");
//		            BasicDBObject field1 = new BasicDBObject();
//		            field1.put("playerID", "51e5b3460240288229000026");
//		            DBObject obj = coll.findOne(field);
//		            System.out.println(obj);
//		                     DBCursor cursor = coll.find();
//		    	        try {
//		    	           while(cursor.hasNext()) {
//		    	        	   count++;
//		    	        	   DBObject obj = cursor.next();
//		    	        	   System.out.println(obj); 
//		    	        	   writer.println(obj);
//		    	        	   
//		    	        	   coll.remove(obj);
//		    	           }
//		    	        } finally {
//		    	           cursor.close();
//		    	        }
//		    	   writer.close();
//	            }
//	        }
    }
   
   static void listCollectionNames(DB db)
    {
        Set<String> colls = db.getCollectionNames();
        for (String s : colls) 
        {
        	System.out.println(s);
        }
    }

   static void findOneObject(DB db, String collectionName, String objectID)
    {
        DBCollection coll = db.getCollection(collectionName);
	    ObjectId field = new ObjectId(objectID);
	    DBObject obj = coll.findOne(field);
	    System.out.println(obj);
    }
   
   static void listCollection(DB db, String collectionName)
    {
        DBCollection coll = db.getCollection(collectionName);
        DBCursor cursor = coll.find();
	        try {
	           while(cursor.hasNext()) {
	        	   DBObject obj = cursor.next();
	        	   System.out.println(obj);    
	           }
	        } finally {
	           cursor.close();
	        }
    }
    static void listNonLogCollections(DB db)
    {
        Set<String> colls = db.getCollectionNames();

        for (String s : colls) 
        {
            if(!s.equals("log"))
            {
	            DBCollection coll = db.getCollection(s);
	            DBCursor cursor = coll.find();
	    	        try {
	    	           while(cursor.hasNext()) {
	    	        	   DBObject obj = cursor.next();
	    	        	   System.out.println(obj);    
	    	           }
	    	        } finally {
	    	           cursor.close();
	    	        }
            }
        }
    }
    
    static void listLog(DB db)
    {
     	DBCollection coll = db.getCollection("log");
    	DBCursor cursor = coll.find();
	        try {
	           while(cursor.hasNext()) {
	        	   DBObject obj = cursor.next();
	        	   System.out.println(obj); 
	           }
	        } finally {
	           cursor.close();
	        }

    }
    
    static void saveAndCleanLog(DB db, String date)
    {
    	File file = new File("log"+date+".txt");
    	if(file.exists()) //don't allow writing over current log files
    	{
    		System.out.println("File already exists");
    		return;
    	}
    	PrintWriter writer = null;
    	DBCursor cursor = null;
    	try 
    	{
    		writer = new PrintWriter("log"+date+".txt", "UTF-8");
            DBCollection coll = db.getCollection("log");
            cursor = coll.find();
            while(cursor.hasNext()) {
        	   DBObject obj = cursor.next();
        	   
        	   writer.println(obj);
        	   coll.remove(obj);
            }
    	}
    	catch(Exception e)
    	{
    		System.out.println(e);
    	} 
    	finally {
    	    cursor.close();
    	    writer.close();
        }
    }
    
    static void listMetadata(DB db, String collectionName)
    {
    	System.out.println("Unless you've modified this, it's not doing what you want");
        DBCollection coll = db.getCollection(collectionName);
        DBCursor cursor = coll.find();
        while(cursor.hasNext()) {
    	   DBObject obj = cursor.next();
    	   DBObject metadata = (DBObject) obj.get("metadata");
		   if(metadata != null)
		   {
			   BasicDBList param = (BasicDBList) metadata.get("parameter");
			   if(param != null)
			   {
				   DBObject firstElem = (DBObject) param.get("0");
				   if(firstElem != null)
				   {
					   System.out.println(firstElem.get("name"));
				   }
			   }
		   }
        }
    }
    
    static void writeFileLocally(GridFS fs, String objectID ) throws Exception
    {
        BasicDBObject field = new BasicDBObject();
        field.put("xmlID", objectID);
		List<GridFSDBFile> cursor = fs.find(field);
        try {
           for(int i=0; i<cursor.size();i++) {
        	   GridFSDBFile obj = cursor.get(i);	   

        	   if(i ==  cursor.size()-2)
        	   {
        		   FileOutputStream outputImage = new FileOutputStream("here.zip");
        		    obj.writeTo( outputImage );
        		    outputImage.close();
        	   }
        	   if(i ==  1)
        	   {
        		   FileOutputStream outputImage = new FileOutputStream("here2.zip");
        		    obj.writeTo( outputImage );
        		    outputImage.close();
        	   }
//        	if(i>0)
//        		fs.remove(obj);
           }
        } finally {
        }
    }

    static void listFiles(GridFS fs)
    {
        DBCursor cursor = fs.getFileList();
        List<DBObject> objList = cursor.toArray();
        for(int i = 0; i<objList.size(); i++)
        {
        	System.out.println(objList.get(i).toString());
        }
    }
    
    static void dropCollection(DB db, String collName)
    {
    	boolean answer = promptForOK("Are you sure you want to remove the collection " + collName + "?");
        
    	if(answer)
    	{
    		System.out.println("Removing collection " + collName);
	    	if (db.collectionExists(collName)) {
	    	    DBCollection myCollection = db.getCollection(collName);
	    	    myCollection.drop();
	    	}
    	}
    	else
    		System.out.print("Not removing collection");
    }
    
    static boolean promptForOK(String prompt)
    {
    	BufferedReader br = new BufferedReader(new InputStreamReader(System.in));
        System.out.print(prompt + " (y/n)");
        String s = "";
		try {
			s = br.readLine();
		} catch (IOException e) {
			e.printStackTrace();
			return false;
		}
       if(s.indexOf('y') == -1)
       {
    	   return false;
       }
       
       return true;
    }

}