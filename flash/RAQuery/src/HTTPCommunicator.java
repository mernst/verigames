import java.io.InputStream;

import org.apache.http.HttpEntity;
import org.apache.http.HttpResponse;
import org.apache.http.client.HttpClient;
import org.apache.http.client.methods.HttpDelete;
import org.apache.http.client.methods.HttpGet;
import org.apache.http.client.methods.HttpPost;
import org.apache.http.client.methods.HttpPut;
import org.apache.http.impl.client.DefaultHttpClient;
import org.json.JSONObject;


public class HTTPCommunicator {

	public JSONObject printResponse(HttpResponse response) throws Exception
	{
		if(response != null)
		{
			System.out.println(response.toString());
			StringBuffer buf = new StringBuffer();
			if(response.getEntity() != null)
			{
				InputStream input = response.getEntity().getContent();
				java.util.Scanner s = new java.util.Scanner(input).useDelimiter("\\A");
			    if( s.hasNext())
			    	buf.append(s.next());

			    System.out.println(buf);
			    JSONObject obj = new JSONObject(buf.toString());
			    return obj;
			}
		}
		
		return null;
	}
	
	public JSONObject printResponseAndEntity(HttpResponse response) throws Exception
	{
		if(response != null)
		{
			System.out.println(response.toString());
			StringBuffer buf = new StringBuffer();
			if(response.getEntity() != null)
			{
				InputStream input = response.getEntity().getContent();
				java.util.Scanner s = new java.util.Scanner(input).useDelimiter("\\A");
			    if( s.hasNext())
			    	buf.append(s.next());

			    JSONObject obj = new JSONObject(buf.toString());
			    System.out.println(buf);
			 	System.out.println(obj.toString());
			 	return obj;
			}
		}
		
		return null;
	}
	
	public JSONObject getJSONFromEntity(HttpResponse response) throws Exception
	{
		if(response != null)
		{
			if(response.getEntity() != null)
			{
				StringBuffer buf = new StringBuffer();
				InputStream input = response.getEntity().getContent();
				java.util.Scanner s = new java.util.Scanner(input).useDelimiter("\\A");
			    if( s.hasNext())
			    	buf.append(s.next());
			    
			    JSONObject obj = new JSONObject(buf);
			    return obj;
			}
		}
		return null;
	}
	
	public HttpResponse doGet(String url, String request) throws Exception 
    {
        HttpClient client = new DefaultHttpClient();
        HttpGet method = new HttpGet(url+request);
        System.out.println(method.toString());
        // Send Get request
        HttpResponse response = client.execute(method);

        return response;
	}
	public HttpResponse doPost(String url, String request) throws Exception 
    {
		return doPost(url, request, null);
    }
	
	public HttpResponse doPost(String url, String request, HttpEntity entity) throws Exception 
    {
        HttpClient client = new DefaultHttpClient();
        HttpPost method = new HttpPost(url+request);
        if(entity != null)
        	method.setEntity(entity);
        // Send POST request
        System.out.println(method.toString());
        if(entity != null)
        {
        	InputStream input = entity.getContent();
			java.util.Scanner s = new java.util.Scanner(input).useDelimiter("\\A");
		    if( s.hasNext())
		    	System.out.println(s.next());
        }
        HttpResponse response = client.execute(method);

        return response;
	}
    
	public HttpResponse doPut(String url, String request) throws Exception 
    {
		return doPut(url, request, null);
    }
	
	public HttpResponse doPut(String url, String request, HttpEntity entity) throws Exception 
    {
		HttpClient client = new DefaultHttpClient();
        HttpPut method = new HttpPut(url+request);
        if(entity != null)
        	method.setEntity(entity);
        // Send POST request
        System.out.println(method.toString());
        if(entity != null)
        {
        	InputStream input = entity.getContent();
			java.util.Scanner s = new java.util.Scanner(input).useDelimiter("\\A");
		    if( s.hasNext())
		    	System.out.println(s.next());
        }
       // Send PUT request
        HttpResponse response = client.execute(method);

        return response;
	}
    
	public HttpResponse doDelete(String url, String request) throws Exception 
    {
        HttpClient client = new DefaultHttpClient();
        HttpDelete method = new HttpDelete(url+request);
        System.out.println(method.toString());
        // Send DELETE request
        HttpResponse response = client.execute(method);

        return response;
	}
}
