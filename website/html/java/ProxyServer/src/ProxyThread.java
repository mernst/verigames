

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
    private static final int BUFFER_SIZE = 32768;
    
   // String testurl = "http://ec2-184-72-152-11.compute-1.amazonaws.com";
	String betaurl = "http://api.pipejam.verigames.com";
	private String url = betaurl;
	private String gameURL = "http://pipejam.verigames.com";
	private String httpport = ":80";

	private int LOG_REQUEST = 0;
	private int LOG_RESPONSE = 1;
	private int LOG_TO_DB = 2;
	private int LOG_ERROR = 3;
	private int LOG_EXCEPTION = 4;
	
	
	String currentLayoutFileID = null;
	String currentConstraintFileID = null;
    public ProxyThread(Socket socket, GridFS fs, DBCollection levelCollection, DBCollection submittedLevelsCollection, 
    		DBCollection savedLevelsCollection, DBCollection submittedLayoutsCollection, DBCollection logCollection) {
        super("ProxyThread");
        this.socket = socket;
        this.fs = fs;
        this.levelCollection = levelCollection;
        this.submittedLevelsCollection = submittedLevelsCollection;
        this.savedLevelsCollection = savedLevelsCollection;
        this.submittedLayoutsCollection = submittedLayoutsCollection;
        this.logCollection = logCollection;
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
            byte[] decodedBytes1 = null;
            byte[] decodedBytes2 = null;
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
	            int file1LengthLength = Integer.parseInt(buf.charAt(0)+"");
	            int file1Length = Integer.parseInt(buf.substring(1, file1LengthLength+1));
	            int file1End = file1LengthLength+file1Length+1;
	            //the count includes new lines from the encoding, but the buffer doesn't, so assume lines are 76 chars
	            //long, and remove the corresponding number of chars
	            double newLineCount = Math.floor(new Double(file1Length).doubleValue()/76.0) - 1;
	            file1End -= newLineCount;
	            String file1 = null;
	            if(buf.length() < file1Length + 10)
	            	file1 = buf.substring(file1LengthLength+1);
	            else
	            	file1 = buf.substring(file1LengthLength+1, file1End);
	            decodedBytes1 = decoder.decodeBuffer(file1);
  
	            if(buf.length() > file1Length + 10)
	            {
	            	int file2LengthLength = Integer.parseInt(buf.charAt(file1End)+"");
		            int file2Length = Integer.parseInt(buf.substring(file1End+1, file1End+1+file2LengthLength));
		            String file2 = buf.substring(file1End+1+file2LengthLength);
		            decodedBytes2 = decoder.decodeBuffer(file2);
	            }
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
            	else if(urlTokens.length == 1) //no params, simple POST
            		response = doPost(urlToCall);
            	else
            	{
            		if(urlTokens[1].indexOf("GET") != -1)
            			response = doGet(urlToCall);
            		else if(urlTokens[1].indexOf("PUT") != -1)
            			response = doPut(urlToCall);
            		else if(urlTokens[1].indexOf("DELETE") != -1)
            			response = doDelete(urlToCall);
            		else if(urlTokens[1].indexOf("DATABASE") != -1)
            			doDatabase(urlToCall, out, decodedBytes1, decodedBytes2);
            		else if(urlTokens[1].indexOf("VERIFY") != -1)
            			response = doVerify(urlToCall);
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
        // Send POST request
        HttpResponse response = client.execute(method);

        return response;
	}
    
    public HttpResponse doPost(String request) throws Exception 
    {
        HttpClient client = new DefaultHttpClient();
        HttpPost method = new HttpPost(url+httpport+request);
        // Send POST request
        HttpResponse response = client.execute(method);

        return response;
	}
    
    public HttpResponse doPut(String request) throws Exception 
    {
        HttpClient client = new DefaultHttpClient();
        HttpPut method = new HttpPut(url+httpport+request);
        // Send POST request
        HttpResponse response = client.execute(method);

        return response;
	}
    
    public HttpResponse doDelete(String request) throws Exception 
    {
        HttpClient client = new DefaultHttpClient();
        HttpDelete method = new HttpDelete(url+httpport+request);
        // Send POST request
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
    
    public void doDatabase(String request, DataOutputStream out, byte[] buf1, byte[] buf2) throws Exception 
    {
    	GridFSDBFile outFile = null;
    	
    	String[] fileInfo = request.split("/");
    	log(LOG_REQUEST, request);

    	if(request.indexOf("/level/save") != -1 || request.indexOf("/level/submit") != -1)
		{
			if(buf1 != null)
				submitLayout(buf1, fileInfo, out);
			if(buf2 != null)
				submitConstraints(buf2, fileInfo, out);
			
		}
		else if(request.indexOf("/level/get/saved") != -1)
		{
			//format:  /level/get/saved/player
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
		else if(request.indexOf("/file/get") != -1)
			{
				//format:  /level/get/doc id/type
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
			//format:  /layout/get/name
			//returns: layout with specified name
    		ObjectId id = new ObjectId(fileInfo[3]);
	    	outFile = fs.findOne(id);	     		
	    	outFile.writeTo(out);
		}
		else if(request.indexOf("/layout/save") != -1)
		{
    		//input should be a layout file
			//format:  /layout/save/related parent xml doc id/layoutname/file contents
    		//returns: success message
			if(buf1 != null)
			{
				submitLayout(buf1, fileInfo, out);
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
	     xmlIn.save();
	     currentConstraintFileID = xmlIn.getId().toString();
	     out.write("file saved".getBytes());
	        
    	if(fileInfo[2].indexOf("submit") != -1)
    		putLevelObjectInCollection(this.submittedLevelsCollection, fileInfo);
    	else
    		putLevelObjectInCollection(this.savedLevelsCollection, fileInfo);
    }
    
    public void putLevelObjectInCollection(DBCollection collection, String[] fileInfo)
    {
    	 DBObject submittedLevelObj = new BasicDBObject();
    	 submittedLevelObj.put("player", fileInfo[3]);
        submittedLevelObj.put("xmlID", fileInfo[4]);
        submittedLevelObj.put("layoutName", fileInfo[5]);
        submittedLevelObj.put("layoutID", currentLayoutFileID);
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
    	
        if(fileInfo.length > 16)
        {
        	properties.put("enjoymentRating", fileInfo[16]);
        	properties.put("difficultyRating", fileInfo[17]);
        }
        DBObject metadata = new BasicDBObject();
        metadata.put("properties", properties);
        submittedLevelObj.put("metadata", metadata);
        log(LOG_TO_DB, submittedLevelObj.toMap().toString());
		WriteResult r2 = collection.insert(submittedLevelObj);
		log(LOG_ERROR, r2.getLastError().toString());
    }

    public HttpResponse doVerify(String request) throws Exception  
    {
        HttpClient client = new DefaultHttpClient();
        HttpGet method = new HttpGet(gameURL+"/verifySession?cookies="+request);
        // Send POST request
        HttpResponse response = client.execute(method);

        return response;
	}
    
    public void log(int type, String line)
    {
     	long threadId = Thread.currentThread().getId();
     	
     	DBObject logObj = new BasicDBObject();
     	logObj.put("time", new Date().toString());
     	logObj.put("type", type);
      	logObj.put("threadID", threadId);
    	logObj.put("line", line);
		logCollection.insert(logObj);
   	
    }
}