import java.io.*;
import com.mongodb.*;
import com.mongodb.gridfs.*;

import java.util.Date;
import java.util.zip.ZipEntry;
import java.util.zip.ZipOutputStream;

public class MongoFileInserter {

	static String mongoAddress = "ec2-184-72-152-11.compute-1.amazonaws.com";
	
    public static void main(String[] args) throws Exception 
    {
    	Object conID = "";
        //Connect to database
        Mongo mongo = new Mongo( mongoAddress );
        String dbName = "gameapi";
        DB db = mongo.getDB( dbName );
        //Create GridFS object
        GridFS fs = new GridFS( db );
        //Save files into database
        
        if(args.length == 1)
        {
	        File file = new File(args[0]);
	        if(file.isDirectory())
	        {
	        	File[] files = file.listFiles(new FilenameFilter() {
	        	    public boolean accept(File directory, String fileName) {
	        	        return fileName.endsWith(".zip") 
	        	        && !fileName.endsWith("Graph.zip") 
	        	        && !fileName.endsWith("Constraints.zip");
	        	    }});
	        	
	        	for(int i=0; i<files.length; i++)
	        	{
	        		File xmlFile = files[i];
	        		GridFSInputFile xmlin = fs.createFile( xmlFile );
	        		 String fileName = xmlFile.getName();
	        		 int index = fileName.lastIndexOf('.');
	        		 fileName = fileName.substring(0, index);
	     	        xmlin.put("name", fileName);
	     	        xmlin.save();
	     	        
	     	        String filePath = xmlFile.getPath();
	     	        //remove xml, and add gxl extension
	     	       int baseIndex = filePath.lastIndexOf('.');
	     	        String filebase = filePath.substring(0, baseIndex);
	     	        File graphFile = new File(filebase+"Graph.zip");
	     	        //Save image into database
	     	        GridFSInputFile gxlin = fs.createFile( graphFile );
	     	        gxlin.setMetaData(new BasicDBObject("name", fileName));
	     	        gxlin.setMetaData(new BasicDBObject("xmlID", xmlin.getId()));
	     	        gxlin.setMetaData(new BasicDBObject("fileID", 0));
	     	        gxlin.save();
	     	        
	     	        File constraintsFile = new File(filebase+"Constraints.zip");
	     	        //Save image into database
	     	        GridFSInputFile conin = fs.createFile( constraintsFile );
	     	        conin.setMetaData(new BasicDBObject("name", fileName+" Starter Constraints"));
	     	        conin.setMetaData(new BasicDBObject("xmlID", xmlin.getId()));
	     	        gxlin.setMetaData(new BasicDBObject("fileID", 0));
	     	        conin.save();
	     	        conID = conin.getId();
	     	        System.out.println(conID);
	        	}
	        }
        }
        
 
      
        
  
	    mongo.close();
    }
}