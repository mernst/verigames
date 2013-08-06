

import java.net.*;
import java.io.*;

import com.mongodb.DB;
import com.mongodb.DBCollection;
import com.mongodb.Mongo;
import com.mongodb.gridfs.GridFS;

public class ProxyServer {
	
	//Tw systems to log in to
	//test db
	//ec2-184-72-152-11.compute-1.amazonaws.com
	//live site
	//ec2-107-21-183-34.compute-1.amazonaws.com
	static public String dbURL = "pipejam.verigames.com";
	static public String version = "1.0b";
    public static void main(String[] args) throws IOException {
    	
        //Connect to database
        Mongo mongo = new Mongo( dbURL );
        String dbName = "gameapi";
        DB db = mongo.getDB( dbName );
        DBCollection levelColl = db.getCollection("Level");
        DBCollection submittedLevelColl = db.getCollection("SubmittedLevels");
        DBCollection savedLevelColl = db.getCollection("SavedLevels");
        DBCollection submittedLayoutColl = db.getCollection("SubmittedLayouts");
        DBCollection logColl = db.getCollection("log");
        //Create GridFS object
        GridFS fs = new GridFS( db );
        
        ServerSocket serverSocket = null;
        boolean listening = true;

        int port = 8001;	//default
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
            System.err.println("Could ps -anot listen on port: " + args[0]);
            System.exit(-1);
        }

        while (listening) {
            new ProxyThread(serverSocket.accept(), fs, levelColl, submittedLevelColl, savedLevelColl, submittedLayoutColl, logColl).start();
        }
        serverSocket.close();
    }
}