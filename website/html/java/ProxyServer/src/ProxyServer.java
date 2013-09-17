

import java.net.*;
import java.util.Date;
import java.io.*;

import com.mongodb.BasicDBObject;
import com.mongodb.DB;
import com.mongodb.DBCollection;
import com.mongodb.DBObject;
import com.mongodb.Mongo;
import com.mongodb.gridfs.GridFS;

public class ProxyServer {
	
	//Tw systems to log in to
	//test db
	//ec2-184-72-152-11.compute-1.amazonaws.com
	//live site
	//ec2-107-21-183-34.compute-1.amazonaws.com
	static public String dbURL = "api.flowjam.verigames.com";
	static public String version = "1.0b";
	static public int port = 8001;	//default
	static DBCollection logColl;
	//set to true to not log, and display log to console
	static public boolean runLocally = false;
	
	//not currently doing anything, will eventually allow for receiving messages but not forward them
	//make sure it's false
	static public boolean testSilent = false;
	
    public static void main(String[] args) throws IOException 
    {
        //Connect to database
        Mongo mongo = new Mongo( dbURL );
        String dbName = "gameapi";
        DB db = mongo.getDB( dbName );
        DBCollection levelColl = db.getCollection("Level");
        DBCollection submittedLevelColl = db.getCollection("SubmittedLevels");
        DBCollection savedLevelColl = db.getCollection("SavedLevels");
        DBCollection submittedLayoutColl = db.getCollection("SubmittedLayouts");
        DBCollection tutorialColl = db.getCollection("CompletedTutorials");
        logColl = db.getCollection("log");
        //Create GridFS object
        GridFS fs = new GridFS( db );
        
        ServerSocket serverSocket = null;
        boolean listening = true;

        try {
            port = Integer.parseInt(args[0]);
        } catch (Exception e) {
            //ignore me
        }

        try {
            serverSocket = new ServerSocket(port);
            System.out.println("Version " + version);
            System.out.println("Started on: " + port);
        } catch (IOException e) {
            System.err.println("Could not listen on port: " + port);
            System.exit(-1);
        }

        while (listening) {
        	try{
            new ProxyThread(serverSocket.accept(), fs, levelColl, submittedLevelColl, savedLevelColl, submittedLayoutColl, logColl, tutorialColl).start();
        	} catch (Exception e) {
                //can redirect this to error log
            	log(ProxyThread.LOG_EXCEPTION, e.toString());
                System.err.println("Encountered exception: " + e);
                e.printStackTrace();
            }
        }
        serverSocket.close();
    }
    
    static public void log(int type, String line)
    {
 	   
    	long threadId = Thread.currentThread().getId();
    	
    	if(ProxyServer.runLocally)
    	{
    		System.out.println("type: " + type + " threadID: " + threadId + " " + line);
    	}
    	else
    	{
	     	
	     	DBObject logObj = new BasicDBObject();
	     	//add both a human readable and a sortable time entry
	     	logObj.put("time", new Date().toString());
	     	logObj.put("ts", new Date());
	     	logObj.put("type", type);
	      	logObj.put("threadID", threadId);
	    	logObj.put("line", line);
	    	logColl.insert(logObj);
    	}
   	
    }
}