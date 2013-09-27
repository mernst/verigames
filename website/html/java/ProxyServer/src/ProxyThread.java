

import java.net.*;
import java.io.*;
import java.util.*;

import org.apache.http.HttpResponse;
import org.apache.http.HttpResponseFactory;
import org.apache.http.HttpStatus;
import org.apache.http.HttpVersion;
import org.apache.http.client.HttpClient;
import org.apache.http.client.methods.*;
import org.apache.http.entity.StringEntity;
import org.apache.http.impl.DefaultHttpResponseFactory;
import org.apache.http.impl.client.DefaultHttpClient;
import org.apache.http.message.BasicStatusLine;

import com.mongodb.*;
import com.mongodb.gridfs.*;

import org.bson.types.ObjectId;

import sun.misc.BASE64Decoder;

public class ProxyThread extends Thread {
    private Socket socket = null;
    private GridFS fs = null;
    private DBCollection levelCollection = null;
    private DBCollection submittedLevelsCollection = null;
    private DBCollection savedLevelsCollection = null;
    private DBCollection submittedLayoutsCollection = null;
    private DBCollection logCollection = null;
    private DBCollection tutorialCollection = null;
    private static final int BUFFER_SIZE = 32768;
    
   // String testurl = "http://ec2-184-72-152-11.compute-1.amazonaws.com";
	String betaurl = "http://api.flowjam.verigames.com";
	private String url = betaurl;
	//used for verifycookie call to verify player
	private String gameURL = "http://flowjam.verigames.com";
	private String httpport = ":80";

	static public int LOG_REQUEST = 0;
	static public int LOG_RESPONSE = 1;
	static public int LOG_TO_DB = 2;
	static public int LOG_ERROR = 3;
	static public int LOG_EXCEPTION = 4;
	
	
	String currentLayoutFileID = null;
	String currentConstraintFileID = null;
    public ProxyThread(Socket socket, GridFS fs, DBCollection levelCollection, DBCollection submittedLevelsCollection, 
    		DBCollection savedLevelsCollection, DBCollection submittedLayoutsCollection, DBCollection logCollection, DBCollection tutorialCollection) {
        super("ProxyThread");
        this.socket = socket;
        this.fs = fs;
        this.levelCollection = levelCollection;
        this.submittedLevelsCollection = submittedLevelsCollection;
        this.savedLevelsCollection = savedLevelsCollection;
        this.submittedLayoutsCollection = submittedLayoutsCollection;
        this.logCollection = logCollection;
        this.tutorialCollection = tutorialCollection;
    }

    public void run() {
        //get input from user
        //send request to server
        //get response from server
        //send response to user

        try {
            DataOutputStream out =
		new DataOutputStream(socket.getOutputStream());
            BufferedReader in = new BufferedReader(
		new InputStreamReader(socket.getInputStream()));
            
            String inputLine;
            int cnt = 0;
            String urlToCall = "";
            String[] tokens = null;
            int contentLength = 0;
             ///////////////////////////////////
            log(LOG_REQUEST, "new request");
            //begin get request from client
            while ((inputLine = in.readLine()) != null) {
            	
            	//this breaks from the while when returning nothing, else the thread will just sit and spin
            	try {
                    StringTokenizer tok = new StringTokenizer(inputLine);
                    tok.nextToken();
                } catch (Exception e) {
                    break;
                }

                //parse the first line of the request to find the url
               if (cnt == 0) {
            	    log(LOG_REQUEST, inputLine);
                    tokens = inputLine.split(" ");
                    urlToCall = tokens[1];
                    //can redirect this to output log
                }
               if(inputLine.toLowerCase().indexOf("content-length") != -1)
               {
            	   String[] contentTokens = inputLine.split(" ");
            	   contentLength = Integer.parseInt(contentTokens[1]);
               }

                cnt++;
            }
            //end get request from client
            ///////////////////////////////////

            //tokens[1] contains the URL, which needs to exist
            if(tokens == null || tokens[1] == null)
            	return;
            
            //do a second read to catch post content - needs to be base64encoded
            byte[] decodedBytes = null;
            int lengthRead = 0;
            if(contentLength != 0)
            {
	            StringBuffer buf = new StringBuffer();
	            while ((inputLine = in.readLine()) != null) {
	               buf.append(inputLine);
	               lengthRead += inputLine.length() + 1; //+1 for line termination char
	              if(lengthRead >= contentLength)
	            	  break;
	            }
	            BASE64Decoder decoder = new BASE64Decoder();
	            decodedBytes = decoder.decodeBuffer(buf.toString());
            }
            BufferedReader rd = null;
            HttpResponse response = null;
            try {
            	String urlTokens[] = tokens[1].split("&");
            	urlToCall = urlTokens[0];
                ///////////////////////////////////
                //begin send request to server, get response from server
            	//check for type of request
            	if(urlTokens.length == 1 && urlTokens[0].indexOf("crossdomain") != -1)
            	{
            		response = doSendCrossDomain(out);
            		//need to write headers in this case
	            	out.write("HTTP/1.1 200\r\nContent-Type: text/x-cross-domain-policy\r\nContent-Size: 239\r\n\r\n".getBytes());
	            	//response =  null;
            	}
            	else
            	{
            		if(ProxyServer.testSilent == true)
            		{
            			out.writeChars("test");
            			out.flush();
            		}
            		if(urlTokens[1].indexOf("GET") != -1)
            			response = doGet(urlToCall);
            		else if(urlTokens[1].indexOf("PUT") != -1)
            			response = doPut(urlToCall);
            		else if(urlTokens[1].indexOf("DELETE") != -1)
            			response = doDelete(urlToCall);
            		else if(urlTokens[1].indexOf("DATABASE") != -1)
            			doDatabase(urlToCall, out, decodedBytes);
            		else if(urlTokens[1].indexOf("URL") != -1)
            			response = doURL(urlToCall, decodedBytes);
            		else
            			response = doPost(urlToCall); //post
            	}
                //end send request to server, get response from server
                ///////////////////////////////////

                ///////////////////////////////////
            	if(response != null)
            	{
            		InputStream isr = response.getEntity().getContent();
	                //begin send response to client
	                byte by[] = new byte[ BUFFER_SIZE ];
	                int index = isr.read( by, 0, BUFFER_SIZE );
	                while ( index != -1 )
	                {
	                  out.write( by, 0, index );
	                  String responseStr = new String(by, "UTF-8");
	                  log(LOG_RESPONSE, responseStr);
	                  index = isr.read( by, 0, BUFFER_SIZE );
	                }
            	}
                out.flush();

                //end send response to client
                ///////////////////////////////////
            } catch (Exception e) {
                //can redirect this to error log
            	log(LOG_EXCEPTION, e.toString());
                System.err.println("Encountered exception: " + e);
                e.printStackTrace();
                //encountered error - just send nothing back, so
                //processing can continue
                out.writeBytes("");
            }

            //close out all resources
            if (rd != null) {
                rd.close();
            }
            if (out != null) {
                out.close();
            }
//            if (in != null) {
//                in.close();
//            }
            if (socket != null) {
                socket.close();
            }

        } catch (IOException e) {
            e.printStackTrace();
            log(LOG_EXCEPTION, e.toString());
        }
    }
    
    public HttpResponse doGet(String request) throws Exception 
    {
        HttpClient client = new DefaultHttpClient();
        HttpGet method = new HttpGet(url+httpport+request);
        log(LOG_REQUEST, url+httpport+request);
        // Send GET request
        HttpResponse response = client.execute(method);

        return response;
	}
    
    public HttpResponse doPost(String request) throws Exception 
    {
        HttpClient client = new DefaultHttpClient();
        HttpPost method = new HttpPost(url+httpport+request);
        log(LOG_REQUEST, url+httpport+request);
        // Send POST request
        HttpResponse response = client.execute(method);

        return response;
	}
    
    public HttpResponse doPut(String request) throws Exception 
    {
        HttpClient client = new DefaultHttpClient();
        HttpPut method = new HttpPut(url+httpport+request);
        log(LOG_REQUEST, url+httpport+request);
        // Send PUT request
        HttpResponse response = client.execute(method);

        return response;
	}
    
    public HttpResponse doDelete(String request) throws Exception 
    {
        HttpClient client = new DefaultHttpClient();
        HttpDelete method = new HttpDelete(url+httpport+request);
        log(LOG_REQUEST, url+httpport+request);
        // Send DELETE request
        HttpResponse response = client.execute(method);

        return response;
	}
    
    public HttpResponse doSendCrossDomain(DataOutputStream out) throws Exception 
    {
    	String crossDomainFile = 
    		"<?xml version=\"1.0\"?>" +
    		"<cross-domain-policy>" +
    		"<site-control permitted-cross-domain-policies=\"all\"/>" +
    		"<allow-access-from domain=\"*.cs.washington.edu\" to-ports=\"8001\"/>" +
    		"<allow-access-from domain=\"*.verigames.com\" to-ports=\"8001\"/>" +
    		"<allow-http-request-headers-from domain=\"*\" headers=\"*\"/>" +
    		"</cross-domain-policy>";
			
    	HttpResponseFactory factory = new DefaultHttpResponseFactory();
    	HttpResponse response = factory.newHttpResponse(new BasicStatusLine(HttpVersion.HTTP_1_1, HttpStatus.SC_OK, null), null);
    	response.addHeader("Content-Type", "text/x-cross-domain-policy");
    	response.addHeader("Content-Size", new Integer(crossDomainFile.length()).toString());
    	response.setEntity(new StringEntity(crossDomainFile));
    	
    	return response;
	}
    
    public void doDatabase(String request, DataOutputStream out, byte[] buf) throws Exception 
    {
    	GridFSDBFile outFile = null;
    	
    	log(LOG_REQUEST, ProxyServer.dbURL);
    	String[] fileInfo = request.split("/");
    	log(LOG_REQUEST, request);

    	if(request.indexOf("/level/save") != -1 || request.indexOf("/level/submit") != -1)
		{
			submitConstraints(buf, fileInfo, out);
			
		}
		else if(request.indexOf("/level/get/saved") != -1)
		{
			if(fileInfo.length < 5)
			{
				out.write("Error: no player ID".getBytes());
				log(LOG_ERROR, "Error: no player ID");
				return;
			}
			//format:  /level/get/saved/player id
			//returns: list of all saved levels associated with the player id
    		StringBuffer buff = new StringBuffer(request+"//");
    		DBObject nameObj = new BasicDBObject("player", fileInfo[4]);
    		   DBCursor cursor = savedLevelsCollection.find(nameObj);
            try {
            	while(cursor.hasNext()) {
 	        	   DBObject obj = cursor.next();
		        	   buff.append(obj.toString());  
		           }
		           out.write(buff.toString().getBytes());
		        } finally {
		        }
		}
		else if(request.indexOf("/level/delete") != -1) //delete saved level
		{
			if(fileInfo.length < 4)
			{
				out.write("Error: no level id to delete".getBytes());
				log(LOG_ERROR, "Error: no player ID");
				return;
			}
			//format:  /level/delete/record id
			// deletes the record id from the saved levels collection
			ObjectId id = new ObjectId(fileInfo[3]);
	        BasicDBObject query = new BasicDBObject();
	        query.put("_id", id);
            try {
            	savedLevelsCollection.remove(query);
		        out.write("{success: true}".getBytes());
	        	log(LOG_RESPONSE, "level deleted "+fileInfo[3]);
		    } 
            catch (Exception e){
		        	out.write("{success: false}".getBytes());
		        	if(fileInfo[2] != null)
		        		log(LOG_ERROR, "Error: level not deleted "+fileInfo[2]);
		        	else
		        		log(LOG_ERROR, "Error: delete missing level id");
		        }
		}
		else if(request.indexOf("/file/get") != -1)
		{
			if(fileInfo.length < 4)
			{
				out.write("Error: no level ID".getBytes());
				log(LOG_ERROR, "Error: no level ID");
				return;
			}
			//format:  /level/get/doc id
			//returns: xml file with doc id
	    	ObjectId id = new ObjectId(fileInfo[3]);
	    	outFile = fs.findOne(id);	     		
	    	outFile.writeTo(out);
			}
		else if(request.indexOf("/level/metadata/get/all") != -1)
		{
			//format:  /level/metadata/get/all
			//returns: metadata records for all levels
    		StringBuffer buff = new StringBuffer(request+"//");
	    	DBCursor cursor = levelCollection.find();
	    	try {
		           while(cursor.hasNext()) {
		        	   DBObject obj = cursor.next();
		        	   buff.append(obj.toString());  
		           }
		           out.write(buff.toString().getBytes());
		        } finally {
		           cursor.close();
		        }
		}
		else if(request.indexOf("/layout/get/all") != -1)
		{
			if(fileInfo.length < 5)
			{
				out.write("Error: no xml ID".getBytes());
				log(LOG_ERROR, "Error: no xml ID");
				return;
			}
			
			//format:  /layout/get/all/xmlID
			//returns: list of all layouts associated with the xmlID
    		StringBuffer buff = new StringBuffer(request+"//");
    		DBObject nameObj = new BasicDBObject("xmlID", fileInfo[4]+'L');
    		   DBCursor cursor = this.submittedLayoutsCollection.find(nameObj);
            try {
            	while(cursor.hasNext()) {
 	        	   DBObject obj = cursor.next();
		        	   buff.append(obj.toString());  
		           }
		           out.write(buff.toString().getBytes());
		        } finally {
		        }
		}
    	else if(request.indexOf("/layout/get") != -1)
		{
    		if(fileInfo.length < 4)
			{
				out.write("Error: no layout ID".getBytes());
				log(LOG_ERROR, "Error: no layout ID");
				return;
			}
			//format:  /layout/get/name
			//returns: layout with specified name
    		ObjectId id = new ObjectId(fileInfo[3]);
	    	outFile = fs.findOne(id);	     		
	    	outFile.writeTo(out);
		}
		else if(request.indexOf("/layout/save") != -1)
		{
    		//input should be a layout file
			//format:  /layout/save/playerID/related parent xml doc id/layoutname::description/file contents
    		//returns: success message
			if(buf != null)
			{
				submitLayout(buf, fileInfo, out);
			}
		}
		else if(request.indexOf("/tutorial/level/complete") != -1)
		{
    		if(fileInfo.length < 6)
			{
				out.write("Error: tutorial info not saved".getBytes());
				log(LOG_ERROR, "Error: tutorial info not saved");
				return;
			}
    		DBObject levelObj = new BasicDBObject();
			levelObj.put("playerID", fileInfo[4]);
	        levelObj.put("levelID", fileInfo[5]);
			log(LOG_TO_DB, levelObj.toMap().toString());
			WriteResult r1 = tutorialCollection.insert(levelObj);
			log(LOG_ERROR, r1.getLastError().toString());
			
			out.write("{success: true}".getBytes());
		}
		else if(request.indexOf("/tutorial/levels/completed") != -1)
		{
			if(fileInfo.length < 5)
			{
				out.write("Error: no player ID".getBytes());
				log(LOG_ERROR, "Error: no player ID");
				return;
			}
			//format:  /layout/get/name
			//returns: layout with specified name
			BasicDBObject findobj = new BasicDBObject();
			findobj.put("playerID", fileInfo[4]);
	        DBCursor cursor = tutorialCollection.find(findobj);	  
	        StringBuffer buff = new StringBuffer(request+"//");
	        try {
            	while(cursor.hasNext()) {
 	        	   DBObject obj = cursor.next();
		        	   buff.append(obj.toString());  
		           }
		           out.write(buff.toString().getBytes());
		           log(LOG_TO_DB, "tutorial complete info returned");
		        } finally {
		        }
		}
	}
    
    public void submitLayout(byte[] buf, String[] fileInfo, DataOutputStream out) throws Exception
    {
		//input should be a layout file
		//format:  /layout/save/related parent xml doc id/layoutname/file contents
		//returns: success message
		if(buf != null)
		{
	        GridFSInputFile xmlIn = fs.createFile(buf);
	        xmlIn.put("player", fileInfo[3]);
	        xmlIn.put("xmlID", fileInfo[4]+"L");
	        xmlIn.put("name", fileInfo[5]);
	        xmlIn.save();
	        
	        out.write("file saved".getBytes());
	        
	      //add to "SavedLayouts"
	        DBObject levelObj = new BasicDBObject();
			levelObj.put("player", fileInfo[3]);
	        levelObj.put("xmlID", fileInfo[4]+"L");
	        levelObj.put("name", fileInfo[5]);
			levelObj.put("layoutID", xmlIn.getId().toString());
			currentLayoutFileID = xmlIn.getId().toString();
			log(LOG_TO_DB, levelObj.toMap().toString());
			WriteResult r1 = submittedLayoutsCollection.insert(levelObj);
			log(LOG_ERROR, r1.getLastError().toString());
		}
    }
    
    //put the file in the file db, then add the level to level db, based on type
    public void submitConstraints( byte[] buf, String[] fileInfo, DataOutputStream out) throws Exception
    {
    	 GridFSInputFile xmlIn = fs.createFile(buf);
	     xmlIn.put("player", fileInfo[3]);
	     xmlIn.put("xmlID", fileInfo[4]+"C");
	     xmlIn.put("name", fileInfo[7]);
	     if(fileInfo.length > 18)
	    	 xmlIn.put("version", fileInfo[18]); //submit
	     else if(fileInfo.length > 16)
	    	 xmlIn.put("version", fileInfo[16]); //save
	     xmlIn.save();
	     currentConstraintFileID = xmlIn.getId().toString();
	     out.write("file saved".getBytes());
	        
    	if(fileInfo[2].indexOf("submit") != -1)
    	{
    		putLevelObjectInCollection(fileInfo, true);
    	}
    	else
    		putLevelObjectInCollection(fileInfo, false);
    }
    
    public void putLevelObjectInCollection(String[] fileInfo, boolean submitAlso)
    {
    	 DBObject submittedLevelObj = new BasicDBObject();
    	 submittedLevelObj.put("player", fileInfo[3]);
        submittedLevelObj.put("xmlID", fileInfo[4]);
        submittedLevelObj.put("layoutName", fileInfo[5]);
        //assume this is only version 2 files, and we don't have one of these
        //submittedLevelObj.put("layoutID", currentLayoutFileID);
        submittedLevelObj.put("name", fileInfo[7]);
        submittedLevelObj.put("levelId", fileInfo[8]);
        submittedLevelObj.put("score", fileInfo[9]);
        submittedLevelObj.put("constraintsID", currentConstraintFileID);
        
        DBObject properties = new BasicDBObject();
        properties.put("boxes", fileInfo[10]);
        properties.put("lines", fileInfo[11]);
        properties.put("visibleboxes", fileInfo[12]);
        properties.put("visiblelines", fileInfo[13]);
        properties.put("conflicts", fileInfo[14]);
        properties.put("bonusnodes", fileInfo[15]);
    	
        if(submitAlso)
        {
        	properties.put("enjoymentRating", fileInfo[16]);
        	properties.put("difficultyRating", fileInfo[17]);
        	submittedLevelObj.put("version", fileInfo[18]);
        	submittedLevelObj.put("shareWithGroup", 1);
        }
        else
        {
        	submittedLevelObj.put("version", fileInfo[16]);
        	submittedLevelObj.put("shareWithGroup", fileInfo[17]);
        }
        submittedLevelObj.put("createdDate", new Date());
        
        DBObject metadata = new BasicDBObject();
        metadata.put("properties", properties);
        submittedLevelObj.put("metadata", metadata);
        log(LOG_TO_DB, submittedLevelObj.toMap().toString());
        WriteResult r2 = null;
        if(submitAlso)
        {
        	r2 = submittedLevelsCollection.insert(submittedLevelObj);
        	log(LOG_ERROR, r2.getLastError().toString());
        }
        
        r2 = savedLevelsCollection.insert(submittedLevelObj);
		log(LOG_ERROR, r2.getLastError().toString());
    }

    public HttpResponse doURL(String request, byte[] buf) throws Exception  
    {
    	String url = null;
    	String postData = null;
    	
    	url = "http://localhost:3000" + request;
      	log(LOG_TO_DB, url);
     	HttpClient client = new DefaultHttpClient();
    	if(buf != null)
    	{
	       	postData = new String(buf);
	       	log(LOG_TO_DB, postData);
        
	       	HttpPost method = new HttpPost(url);
	       	StringEntity params = new StringEntity(postData);
	       	method.setHeader("Content-type", "application/json");
	       	method.setEntity(params);
	       	HttpResponse response = client.execute(method);
	        return response;
    	}
    	else
    	{
    		HttpGet method = new HttpGet(url);
    		HttpResponse response = client.execute(method);
    		return response;
    	}
	}
    
    public void log(int type, String line)
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
			logCollection.insert(logObj);
    	}
   	
    }
}