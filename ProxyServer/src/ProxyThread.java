

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
    private static final int BUFFER_SIZE = 32768;
    
	private String url = "http://ec2-184-72-152-11.compute-1.amazonaws.com";
	private String httpport = ":80";
	private String authport = ":3000";
    public ProxyThread(Socket socket, GridFS fs, DBCollection levelCollection) {
        super("ProxyThread");
        this.socket = socket;
        this.fs = fs;
        this.levelCollection = levelCollection;
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
            //begin get request from client
            while ((inputLine = in.readLine()) != null) {
            	try {
                    StringTokenizer tok = new StringTokenizer(inputLine);
                    tok.nextToken();
                } catch (Exception e) {
                    break;
                }
                
                //parse the first line of the request to find the url
               if (cnt == 0) {
                    tokens = inputLine.split(" ");
                    urlToCall = tokens[1];
                    //can redirect this to output log
                    System.out.println("Request for : " + urlToCall);
                }
               System.out.println(inputLine);
               if(inputLine.toLowerCase().indexOf("content-length") != -1)
               {
            	   String[] contentTokens = inputLine.split(" ");
            	   contentLength = Integer.parseInt(contentTokens[1]);
               }

                cnt++;
            }
            //end get request from client
            ///////////////////////////////////

            //do a second read to catch post content - needs to be base64encoded
            byte[] decodedBytes = null;
            int lengthRead = 0;
            if(contentLength != 0)
            {
	            StringBuffer buf = new StringBuffer();
	            while ((inputLine = in.readLine()) != null) {
	               System.out.println(inputLine);
	               buf.append(inputLine);
	               lengthRead += inputLine.length() + 1; //+1 for line termination char
	               System.out.println(buf.length()+ " " + lengthRead);
	              if(lengthRead >= contentLength)
	            	  break;
	            }
	            System.out.println(buf.length() + " " + lengthRead);
	            BASE64Decoder decoder = new BASE64Decoder();
	            decodedBytes = decoder.decodeBuffer(buf.toString());
	            
	            System.out.println(decodedBytes.length);
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
            			doDatabase(urlToCall, out, decodedBytes);
            		else if(urlTokens[1].indexOf("AUTH") != -1)
            			response = doAuth(urlToCall);
            	}
                //end send request to server, get response from server
                ///////////////////////////////////

                ///////////////////////////////////
            	if(response != null)
            	{
            		System.out.println(response.toString());

            		InputStream isr = response.getEntity().getContent();
	                //begin send response to client
	                byte by[] = new byte[ BUFFER_SIZE ];
	                int index = isr.read( by, 0, BUFFER_SIZE );
	                while ( index != -1 )
	                {
	                	System.out.println(new String(by));
	                  out.write( by, 0, index );
	                  index = isr.read( by, 0, BUFFER_SIZE );
	                }
            	}
                out.flush();

                //end send response to client
                ///////////////////////////////////
            } catch (Exception e) {
                //can redirect this to error log
                System.err.println("Encountered exception: " + e);
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
    	
    	String[] fileInfo = request.split("/");
	    System.out.println(request);

    	if(request.indexOf("/level/get") != -1)
		{
			//format:  /level/get/doc id/type
			//returns: xml file with doc id
	    	ObjectId id = new ObjectId(fileInfo[3]);
	    	outFile = fs.findOne(id);	     		
	    	System.out.println(outFile.toString());
	    	outFile.writeTo(out);
		}
		else if(request.indexOf("/level/save") != -1)
		{
			//input should be a constraints file
			//format:  /level/save/related parent xml doc id/levelname/score
			//returns: success or failure message
			if(buf != null)
			{
				System.out.println("File length " + buf.length);
				BufferedOutputStream bos = new BufferedOutputStream(new FileOutputStream("file.zip"));
				bos.write(buf);
				bos.flush();
				bos.close();
		        GridFSInputFile xmlIn = fs.createFile(buf);
		        xmlIn.put("xmlID", fileInfo[3]+"C");
		        xmlIn.put("name", fileInfo[4]);
		        xmlIn.put("score", fileInfo[5]);
		        xmlIn.save();
		        String constratintsID = xmlIn.getId().toString();
		        out.write(constratintsID.getBytes());
			}
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
    		List<GridFSDBFile> cursor = fs.find(nameObj);
            try {
               for(int i=0; i<cursor.size();i++) {
            	   DBObject obj = cursor.get(i);
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
    		StringBuffer buff = new StringBuffer(request+"//");
    		DBObject nameObj = new BasicDBObject("name", fileInfo[3]);
	    	DBCursor cursor = levelCollection.find(nameObj);
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
		else if(request.indexOf("/layout/save") != -1)
		{
    		//input should be a layout file
			//format:  /layout/save/related parent xml doc id/layoutname/file contents
    		//returns: success message
			if(buf != null)
			{
				System.out.println("File length " + buf.length);
				BufferedOutputStream bos = new BufferedOutputStream(new FileOutputStream("file.zip"));
				bos.write(buf);
				bos.flush();
				bos.close();
		        GridFSInputFile xmlIn = fs.createFile(buf);
		        xmlIn.put("xmlID", fileInfo[3]+"L");
		        xmlIn.put("name", fileInfo[4]);
		        xmlIn.save();
		        
		        out.write("file saved".getBytes());
			}
		}
	}
    
    public HttpResponse doAuth(String request) throws Exception  
    {
        HttpClient client = new DefaultHttpClient();
        HttpGet method = new HttpGet(url+authport+request);
        // Send POST request
        HttpResponse response = client.execute(method);

        return response;
	}
}