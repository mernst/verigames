import com.mongodb.*;
import com.mongodb.gridfs.*;

import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.FilenameFilter;
import java.io.File;
import java.io.IOException;
import java.io.PrintStream;
import java.io.PrintWriter;
import java.util.Calendar;
import java.util.Date;
import java.util.Dictionary;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.Vector;
import java.util.zip.ZipEntry;
import java.util.zip.ZipInputStream;

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

    static DB db;
	public static void main(String[] args) throws Exception {

	//	String firstArg = args[0];

        //staging game level server
        Mongo mongo = new Mongo( "54.208.82.42" );
      //  staging RA server
     //  Mongo mongo = new Mongo( "ec2-23-22-125-169.compute-1.amazonaws.com" );
        String dbName = "gameapi";
        db = mongo.getDB( dbName );
        
      HashMap<String, String> map = new HashMap<String, String>();
     map.put("xmlID", "52798635a8e0e0e5438239dcL"); 
   //  map.put("xmlID", "52798634a8e0e0e5438239d4L");
     //    map.put("name", "EmptyDesert"); 
     
      //System.out.println(uploadFile("C:\\DemoWorld.gxl", "fs/ostrusted/6"));
 //     removeFile("fs/ostrusted/6", "52ab6b08a8e03bbf0418d1d5");
  //    listFiles("fs/ostrusted/6");
      
//        System.out.println("Level");
 //    SaveFileInfo(db, "Level", map);
  //   SavePlayerSubmissionInfo(db, "SubmittedLevels");
    // 	listFiles("fs");
    //	writeFileLocally("fs", "52d4855727f4030c9139be8a", "test2.zip");
  //     String[] levelIDArray = getConstraintIDs(db, "SubmittedLevels");
   //    for(int index = 0; index < levelIDArray.length; index++)
       { 
    //	   writeFileLocally("fs", levelIDArray[index], levelIDArray[index]+".zip");
       }
  //     System.out.println("SaveLevels");
       listEntries(db, "SubmittedLayouts", map);
//       System.out.println("SubmittedLayouts");
//       listEntriesToFile(db, "SubmittedLevels", map, "SubmittedLevels0115.txt");
       
 //      SaveFileInfo(db, "SubmittedLevels", map, "SubmittedLevels0115.txt");
//      System.out.println("SubmittedLevels");
 //     listEntriesToFile(db, "Level", map, "levels1226.txt");
 //      map.put("playerID", firstArg);
 //      map.put("levelID", "15");
 //     listFilesToFile("fs", "files.txt");
 //     listEntriesToFile(db, "SavedLevels", map, "savedLevels.txt");
//      downloadSavedLevel(db, "fs", "5266f4b3e4b06170777f9dee", "test.zip");
        // listLog(db);
 //           saveAndCleanLog(db, "1211");
        
       listCollectionNames(db);
    //     listCollection(db, "SavedLevels");
	    mongo.close();
	}
	
	
	static void listEntries(DB db, String collectionName, HashMap<String, String> searchKeys)
	{
		BasicDBObject field = new BasicDBObject();
		for (Map.Entry<String, String> entry : searchKeys.entrySet()) {
		    String key = entry.getKey();
		    String value = entry.getValue();
		    field.put(key, value);
		}
		
		DBCollection collection = db.getCollection(collectionName);
		DBCursor cursor = null;
		 try { 
			 cursor = collection.find(field);
			 while(cursor.hasNext()) {
           	DBObject obj = cursor.next();
            System.out.println(obj);
           }
        } finally {
        	if(cursor != null)
        		cursor.close();
        }
	}
	
	static void listEntriesToFile(DB db, String collectionName, HashMap<String, String> searchKeys, String fileName) throws Exception
	{
		BasicDBObject field = new BasicDBObject();
		for (Map.Entry<String, String> entry : searchKeys.entrySet()) {
		    String key = entry.getKey();
		    String value = entry.getValue();
		    field.put(key, value);
		}
		
		FileOutputStream outputFile = new FileOutputStream(fileName);
		PrintStream out = new PrintStream(outputFile);
		DBCollection collection = db.getCollection(collectionName);
		DBCursor cursor = null;
		 try { 
			 cursor = collection.find(field);
			 while(cursor.hasNext()) {
           	DBObject obj = cursor.next();
            out.print(obj.toString() + '\n'); 
            System.out.println(obj);
           }
        } finally {
        	if(cursor != null)
        		cursor.close();
        }
		outputFile.close();
	}
	
	static void SaveFileEntriesToFiles(DB db, String collectionName, HashMap<String, String> searchKeys, String fileName) throws Exception
	{
		BasicDBObject field = new BasicDBObject();
		for (Map.Entry<String, String> entry : searchKeys.entrySet()) {
		    String key = entry.getKey();
		    String value = entry.getValue();
		    field.put(key, value);
		}
		
		HashMap<String, Integer> nameCount = new HashMap<String, Integer>();
		HashMap<String, String> levelNames = new HashMap<String, String>();
		DBCollection collection = db.getCollection(collectionName);
		DBCursor cursor = null;
		 try { 
			 cursor = collection.find(field);
			 while(cursor.hasNext()) {
           	DBObject obj = cursor.next();
     //       out.print(obj.toString() + '\n'); 
 
           	if(!(obj.containsKey("xmlID") && obj.containsKey("name") && obj.containsKey("constraintsID")))
           			continue;
           	
           	if(!obj.containsKey("player") || obj.get("player").toString().equals("51e5b3460240288229000026"))
       			continue;
           	
           	String xmlID = obj.get("xmlID").toString();
            String levelName = obj.get("name").toString();
            
            int newVal = 1;
            if(nameCount.containsKey(levelName))
            {
            	Integer value = nameCount.get(levelName);
            	newVal = value.intValue() + 1;
            	nameCount.put(levelName, new Integer(newVal));
            }
            else
            	nameCount.put(levelName, new Integer(1));  
            
            File dir = new File("SubmittedLevels/"+xmlID);
            if(!dir.exists())
            	dir.mkdir();
            
            String constraintsID = obj.get("constraintsID").toString();
            writeFileLocally("fs", constraintsID, "SubmittedLevels/"+xmlID+ "/" + levelName+newVal+".zip");

            System.out.println(obj);
           }
        } finally {
        	if(cursor != null)
        		cursor.close();
        }
	}
	
	static void SaveFileInfo(DB db, String collectionName, HashMap<String, String> searchKeys) throws Exception
	{
		BasicDBObject field = new BasicDBObject();
		for (Map.Entry<String, String> entry : searchKeys.entrySet()) {
		    String key = entry.getKey();
		    String value = entry.getValue();
		    field.put(key, value);
		}
		System.out.println("start");
		HashMap<String, Integer> nameCount = new HashMap<String, Integer>();
		HashMap<String, String> prefs = new HashMap<String, String>();
		HashMap<String, String> levelToName = new HashMap<String, String>();
		DBCollection collection = db.getCollection(collectionName);
		DBCursor cursor = null;
		 try { 
			 cursor = collection.find(field);
			 while(cursor.hasNext()) {
           	DBObject obj = cursor.next();
 
          	
           	String xmlID = obj.get("xmlID").toString();
            String levelName = obj.get("name").toString();
            levelToName.put(xmlID, levelName);
            
            int conflicts = 0;
            int numboxes = 0;
            DBObject metadataObj = (DBObject)obj.get("metadata");
            if(metadataObj != null)
            {
	            DBObject propertiesObj = (DBObject)metadataObj.get("properties");
	            if(propertiesObj != null)
	            {
	            	conflicts = new Integer((String)propertiesObj.get("conflicts").toString());
	            	numboxes =  new Integer((String)propertiesObj.get("boxes").toString());
	            }
            }
             
            System.out.println(numboxes);
           
            HashMap<String, String> submap = new HashMap<String, String>();
            submap.put("xmlID", xmlID); 
            
            
        //   getFileInfo(db, "SubmittedLevels", submap);
            

           }
        } finally {
        	if(cursor != null)
        		cursor.close();
        }
	}
	
	static void getFileInfo(DB db, String collectionName, HashMap<String, String> searchKeys) throws Exception
	{
		BasicDBObject field = new BasicDBObject();
		for (Map.Entry<String, String> entry : searchKeys.entrySet()) {
		    String key = entry.getKey();
		    String value = entry.getValue();
		    field.put(key, value);
		}
		
		Vector<Object[]> holders = new Vector<Object[]>();
		
		DBCollection collection = db.getCollection(collectionName);
		DBCursor cursor = null;
		
		int count = 0;
		int prefs = 0;

		 try { 
				 cursor = collection.find(field);
				 while(cursor.hasNext()) 
				 {
		           	DBObject obj = cursor.next();
		           	
			      	if(!obj.containsKey("player") || obj.get("player").toString().equals("51e5b3460240288229000026"))
			 			continue;
			          	
		            
		            
		            DBObject metadataObj = (DBObject)obj.get("metadata");
		            if(metadataObj != null)
		            {
			            DBObject propertiesObj = (DBObject)metadataObj.get("properties");
			            if(propertiesObj != null)
			            {
			            	String prefVal = (String)propertiesObj.get("preference");
			            	if(prefVal != null)
			            	{
			            		if((new Integer(prefVal)).intValue() != 250)
			            		{
			            			prefs += (new Integer(prefVal)).intValue();
			            			count++;
			            		}
			            	}
			            }
		            }
		            
			        Object[] h = new Object[3];
			        h[0] = (String)obj.get("player");
		            Date createddate = (Date)obj.get("createdDate");
		            Calendar cal = Calendar.getInstance();
		            cal.setTime(createddate);
		            int month = cal.get(Calendar.MONTH) + 1;
		            int day = cal.get(Calendar.DAY_OF_MONTH);
		            int year = cal.get(Calendar.YEAR);
		            h[1] = month + "/" + day  + "/" + year;
		            h[2] = new Integer((String)obj.get("score"));
		            
		            
		            holders.add(h);
		            
		          }
				 float prefAve = 0;
				 	if(count > 0)
				 		prefAve = prefs/count;
		            System.out.print("," + count + "," + prefAve);
		          
		        //   for(Object[] h:holders)
		        //	   System.out.print("," + h[2]);

				 System.out.print("\n");
        } finally {
        	if(cursor != null)
        		cursor.close();
        }
	}
	
	static public void SavePlayerSubmissionInfo(DB db, String collectionName) throws Exception
	{
		DBCollection collection = db.getCollection(collectionName);
		DBCursor cursor = null;
		int count = 0;
		 try { 
			 HashMap<String, Vector<DateHolder>> playerToDates = new HashMap<String, Vector<DateHolder>>();
				 cursor = collection.find();
				 while(cursor.hasNext()) 
				 {
		           	DBObject obj = cursor.next();
		           	String player = (String)obj.get("player");
		            Date createddate = (Date)obj.get("createdDate");
		            if(createddate != null)
		            {
			            Calendar cal = Calendar.getInstance();
			            cal.setTime(createddate);
			            int month = cal.get(Calendar.MONTH) + 1;
			            int day = cal.get(Calendar.DAY_OF_MONTH);
			            int year = cal.get(Calendar.YEAR);
			            String date = month + "/" + day  + "/" + year;
			           
			           	count++;
			            System.out.println(player + " " + date);
			            if(playerToDates.get(player) != null)
			            {
			            	System.out.println("found player");
			            	Vector<DateHolder> holder = playerToDates.get(player);
			            	boolean dateFound = false;
			            	for(DateHolder dh : holder)
			            	{
			            		if(dh.date.equals(date))
			            		{
			            			System.out.println("found date");
			            			dh.count++;
			            			dateFound = true;
			            		}
			            	}
			            	if(!dateFound)
			            	{
				            	DateHolder dh = new DateHolder();
				            	dh.date = date;
				            	dh.count = 1;
				            	dh.player = player;
				            	holder.add(dh);
			            	}
			            		
			            }
			            else
			            {
			            	Vector<DateHolder> holder = new Vector<DateHolder>();
			            	DateHolder dh = new DateHolder();
			            	dh.date = date;
			            	dh.count = 1;
			            	dh.player = player;
			            	holder.add(dh);
			            	playerToDates.put(player, holder);
			            }
		            }
				 }
			 	PrintWriter writer = new PrintWriter("player.csv", "UTF-8");
			 	
			 	Iterator it = playerToDates.entrySet().iterator();
			    while (it.hasNext()) {
			        Map.Entry pairs = (Map.Entry)it.next();
			        String player = (String)pairs.getKey();
			        Vector<DateHolder> dates = (Vector<DateHolder>)pairs.getValue();
			        writer.print(player + "," + dates.size());
			        for(DateHolder dh:dates)
			        {
			        	
			        	writer.print("," + dh.count);
			        }
			        
			        writer.println("");

			    }
			    
		        writer.close(); 
		 } finally {
	        	if(cursor != null)
	        		cursor.close();
	        }
		 
		 System.out.println("");
		 System.out.println(count);
	}
	
	static public void unZipIt(String zipFile, String outputFile){
		 
	     byte[] buffer = new byte[1024];
	 
	     try{
	 
	    	//create output directory is not exists
	 
	    	//get the zip file content
	    	ZipInputStream zis = 
	    		new ZipInputStream(new FileInputStream(zipFile));
	    	//get the zipped file list entry
	    	ZipEntry ze = zis.getNextEntry();
	 
	    	while(ze!=null){
	 
	    	   String fileName = ze.getName();
	           File newFile = new File(outputFile);
	 
	           System.out.println("file unzip : "+ newFile.getAbsoluteFile());
	 
	            //create all non exists folders
	            //else you will hit FileNotFoundException for compressed folder
	            new File(newFile.getParent()).mkdirs();
	 
	            FileOutputStream fos = new FileOutputStream(newFile);             
	 
	            int len;
	            while ((len = zis.read(buffer)) > 0) {
	       		fos.write(buffer, 0, len);
	            }
	 
	            fos.close();   
	            ze = zis.getNextEntry();
	    	}
	 
	        zis.closeEntry();
	    	zis.close();
	 
	    	System.out.println("Done");
	 
	    }catch(IOException ex){
	       ex.printStackTrace(); 
	    }
	   }    
	
	static void listEntriesAndRemove(DB db, String collectionName, HashMap<String, String> searchKeys)
	{
		BasicDBObject field = new BasicDBObject();
		for (Map.Entry<String, String> entry : searchKeys.entrySet()) {
		    String key = entry.getKey();
		    String value = entry.getValue();
		    field.put(key, value);
		}
		
		DBCollection collection = db.getCollection(collectionName);
		DBCursor cursor = null;
		 try { 
			 cursor = collection.find(field);
			 while(cursor.hasNext()) {
           	DBObject obj = cursor.next();
               System.out.println(obj);
               collection.remove(obj);
           }
        } finally {
        	if(cursor != null)
        		cursor.close();
        }
	}
	
	static public void listFiles(String fsname)
	{
		GridFS fs = new GridFS(db, fsname);
        DBCursor cursor = fs.getFileList();
        try { 
            while(cursor.hasNext()) {
            	DBObject obj = cursor.next();
                System.out.println(obj);
            }
         } finally {
            cursor.close();
         }
	}
	
	static public void listFilesToFile(String fsname, String fileName) throws Exception
	{
		GridFS fs = new GridFS(db, fsname);
        DBCursor cursor = fs.getFileList();
        
		FileOutputStream outputFile = new FileOutputStream(fileName);
		PrintStream out = new PrintStream(outputFile);

        try { 
            while(cursor.hasNext()) {
            	DBObject obj = cursor.next();
            	out.print(obj.toString() + '\n'); 
                System.out.println(obj);
            }
         } finally {
            cursor.close();
         }
         
         outputFile.close();
	}
	
	//constraintIDs are used to map a level entry to the file
	static public String[] getConstraintIDs(DB db, String collectionName)
	{
		DBCollection collection = db.getCollection(collectionName);
		int length = (int)collection.count();
		
		String[] idArray = new String[length];
		int index = 0;
		
		DBCursor cursor = null;
		 try { 
			 cursor = collection.find();
			 while(cursor.hasNext()) {
           	DBObject obj = cursor.next();
           	idArray[index] = obj.get("constraintsID").toString();
            System.out.println(idArray[index]);
            index++;
           }
        } finally {
        	if(cursor != null)
        		cursor.close();
        }
        
        return idArray;
	}
	
	static public void downloadSavedLevel(DB db, String fsname, String levelID, String outputFileName) throws Exception
	{
		DBObject level = findOneEntry(db, "SavedLevels", "levelId", levelID);
		Object obj = null;
		if(level != null)
		{
			obj = level.get("constraintsID");

			String objString = obj.toString();
			writeFileLocally(fsname, objString, outputFileName);
		}
	}
	
	static public DBObject findEntryByID(DB db, String collectionName, String idStr)
	{
		DBCollection collection = db.getCollection(collectionName);
		ObjectId id = new ObjectId(idStr);
		
		DBObject foundOne = null;
		try { 
			foundOne = collection.findOne(id);
       } finally {
       }
       return foundOne;
	}
	
	static public DBObject findOneEntry(DB db, String collectionName, String key, String value)
	{
		DBCollection collection = db.getCollection(collectionName);
		BasicDBObject field = new BasicDBObject();
		field.put(key, value);
		DBCursor cursor = null;
		DBObject obj = null;
		try { 
			 cursor = collection.find(field);
			 if(cursor.hasNext())
				 obj = cursor.next();
       } finally {
       	if(cursor != null)
       		cursor.close();
       }
       return obj;
	}
	
	static public void uploadFile(String filename) throws Exception
	{
		uploadFile(filename, "fs");
	}
	
	static public String uploadFile(String filename, String gridFSName) throws Exception
	{
		File newFile = new File(filename);
        //Save layout into database
		GridFS fs = new GridFS( db, gridFSName );
        GridFSInputFile inputFile = fs.createFile(newFile);
        inputFile.save();
        return inputFile.getId().toString();
	}
	
	static public void removeFile(String gridFSName, String objectID) throws Exception
	{
		GridFS fs = new GridFS( db, gridFSName );
        ObjectId id = new ObjectId(objectID);

        fs.remove(id);
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
	
	   static void findOneObjectByID(DB db, String collectionName, String objectID)
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
    
    static void writeFileLocally(String gridFSName, String objectID, String outputfilename ) throws Exception
    {
    	ObjectId field = new ObjectId(objectID);
    	GridFS fs = new GridFS( db, gridFSName );
		GridFSDBFile obj = fs.find(field);
        try {
        		FileOutputStream outputFile = new FileOutputStream(outputfilename);
        		obj.writeTo( outputFile );
        		outputFile.close();
        } finally {
        }
    }
    
    static private class PlayerInfoHolder
	{
		int score;
		String date;
		String player;
		int count;
	}
    
    static private class DateHolder
	{
		String date;
		String player;
		int count;
	}
    
    
}

