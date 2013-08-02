import java.io.*;

import com.mongodb.*;
import com.mongodb.gridfs.*;

import java.util.ArrayList;

import org.bson.types.ObjectId;

public class MongoFileInserter {

	static String mongoAddress = "ec2-184-72-152-11.compute-1.amazonaws.com";
	DB db = null;
	GridFS fs = null;
	
	public String xmlID;
	public String layoutID;
	public String constraintsID;
	
    public static void main(String[] args) throws Exception 
    {
         //Connect to database
        Mongo mongo = new Mongo( mongoAddress );
        String dbName = "gameapi";
        DB db = mongo.getDB( dbName );
         
        MongoFileInserter inserter = new MongoFileInserter(db);
        
        if(args.length == 1)
        {
	        File fileDir = new File(args[0]);
	        if(fileDir.isDirectory())
	        {
	        	File[] files = fileDir.listFiles(new FilenameFilter() {
	        	    public boolean accept(File directory, String fileName) {
	        	        return fileName.endsWith(".zip") 
	        	        && !fileName.endsWith("Layout.zip") 
	        	        && !fileName.endsWith("Constraints.zip");
	        	    }});
	        	
	        	for(int i=0; i<files.length; i++)
	        	{
	        		File xmlFile = files[i];
	        		inserter.addLevelFiles(xmlFile);
	        	}
	        }
        }
 
	    mongo.close();
    }
    
    public MongoFileInserter(DB _db)
    {
    	db = _db;
    	fs = new GridFS( db );
    }
    
    public void addLevelFiles(File xmlFile) throws IOException
    {
		GridFSInputFile xmlin = fs.createFile( xmlFile );
		 String fileName = xmlFile.getName();
		 int index = fileName.lastIndexOf('.');
		 fileName = fileName.substring(0, index);
        xmlin.put("name", fileName);
        xmlin.save();
        xmlID = xmlin.getId().toString();
        
        String filePath = xmlFile.getPath();
        //remove xml, and add gxl extension
       int baseIndex = filePath.lastIndexOf('.');
        String filebase = filePath.substring(0, baseIndex);
        
        File layoutFile = new File(filebase+"Layout.zip");
        //Save layout into database
        GridFSInputFile layoutIn = fs.createFile( layoutFile );
        layoutIn.put("xmlID", xmlin.getId().toString()+"L");
        layoutIn.put("name", "Starter Layout");
        layoutIn.save();
        layoutID = layoutIn.getId().toString();
        
        File constraintsFile = new File(filebase+"Constraints.zip");
        //Save image into database
        GridFSInputFile conin = fs.createFile( constraintsFile );
        conin.put("xmlID", xmlin.getId().toString()+"C");
        conin.put("name", "Starter Constraints");
        conin.save();
        constraintsID = conin.getId().toString();
    }
}