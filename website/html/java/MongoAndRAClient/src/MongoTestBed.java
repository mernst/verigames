import com.mongodb.*;
import com.mongodb.gridfs.*;

import java.io.FileOutputStream;
import java.io.FilenameFilter;
import java.io.File;
import java.io.PrintWriter;
import java.util.List;
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
        Mongo mongo = new Mongo( "api.flowjam.verigames.com" );
      //  staging RA server
     //  Mongo mongo = new Mongo( "ec2-23-22-125-169.compute-1.amazonaws.com" );
        String dbName = "gameapi";
        DB db = mongo.getDB( dbName );
        //Create GridFS object
        GridFS fs = new GridFS( db );
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
        
        Set<String> colls = db.getCollectionNames();

 //       String levelName = "";
        int count = 0;
        for (String s : colls) {
//        	if(s.equalsIgnoreCase("level") || s.equalsIgnoreCase("levels"))
//        	{
//        		levelName = s;
//        	}
//        	if(count > 34)
        	{
	            System.out.println("Collection " + s);
	            if(s.equals("log"))
	            {
	       //     	PrintWriter writer = new PrintWriter(s+".txt", "UTF-8");
		            DBCollection coll = db.getCollection(s);
		            ObjectId field = new ObjectId("521692a6a8e0e7d8db85c971");
		           // field.put("$oid", "51ed5bb9a8e0be024c017fa2");
		            BasicDBObject field1 = new BasicDBObject();
		            field1.put("_id", field);
		            //   DBCursor cursor = coll.find(field1);
		                   DBCursor cursor = coll.find();
		    	        try {
		    	           while(cursor.hasNext()) {
		    	        	   count++;
		    	        	   DBObject obj = cursor.next();
		    	        	   System.out.println(obj); 
		    	      //  	   writer.println(obj);
		    	        	   
		    	     //   	   coll.remove(obj);
		    	           }
		    	        } finally {
		    	           cursor.close();
		    	        }
		  //  	   writer.close();

	            }
	        }
    	    count++;
 //   	    if(count > 70)
 //   	        break;
        }
//        DBCollection coll = db.getCollection("Level");
//        DBObject obj1 = coll.findOne("51802cf5e4b03743be6d8f42");
//		   System.out.println(obj1);
//    	   DBObject metadata = (DBObject) obj1.get("metadata");
//    	   if(metadata != null)
//    	   {
//        	   BasicDBList param = (BasicDBList) metadata.get("parameter");
//        	   if(param != null)
//        	   {
//	        	   DBObject firstElem = (DBObject) param.get("0");
//	        	   if(firstElem != null)
//	        	   {
//	        		   System.out.println(firstElem.get("name"));
//	        	//	   firstElem.put("name", "test");
//	        	//	   coll.save(firstElem);
//	        	   }
//        	   }
//    	   }
//        System.out.println("start");
//        BasicDBObject field = new BasicDBObject("xmlID", "519cfaad4942a9056790d98fC");
//      field.put("xmlID", "51eccd89a8e04b0d79b61d87");
//		   List<GridFSDBFile> cursor = fs.find(field);
//        try {
//           for(int i=0; i<cursor.size();i++) {
//        	   GridFSDBFile obj = cursor.get(i);
//        	   System.out.println(obj);	 
//        	   
////
////        	   if(i ==  cursor.size()-2)
////        	   {
////        		   FileOutputStream outputImage = new FileOutputStream("here.zip");
////        		    obj.writeTo( outputImage );
////        		    outputImage.close();
////        	   }
//        	   if(i ==  1)
//        	   {
//        		   FileOutputStream outputImage = new FileOutputStream("here2.zip");
//        		    obj.writeTo( outputImage );
//        		    outputImage.close();
//        	   }
////        	if(i>0)
////        		fs.remove(obj);
//           }
//        } finally {
//        }
//        System.out.println("start");
//        DBCollection coll = db.getCollection("Level");
//		   DBCursor cursor = coll.find();
//	        try {
//	           while(cursor.hasNext()) {
//	        	   DBObject obj = cursor.next();
//	        	   System.out.println(obj);  
//	        	   if(removeLevels)
//	        		   coll.remove(obj);
//	           }
//	        } finally {
//	           cursor.close();
//	        }
//	        System.out.println("end");
//        coll = db.getCollection("User");
//        cursor = coll.find();
//        try {
//           while(cursor.hasNext()) {
//               System.out.println(cursor.next());
//           }
//        } finally {
//           cursor.close();
//        }
//        
//        coll = db.getCollection("OAuth2Client");
//        cursor = coll.find();
//        try {
//           while(cursor.hasNext()) {
//               System.out.println(cursor.next());
//           }
//        } finally {
//           cursor.close();
//        }
        
//        DBCursor cursor = fs.getFileList();
//        List<DBObject> objList = cursor.toArray();
//        for(int i = 0; i<objList.size(); i++)
//        {
//        	System.out.println(objList.get(i).toString());
//        }
 
	    mongo.close();
    }
    

}