import java.util.ArrayList;

import org.apache.http.HttpEntity;
import org.apache.http.HttpResponse;
import org.apache.http.entity.StringEntity;
import org.json.JSONArray;
import org.json.JSONObject;
import org.json.JSONString;


public class RACommunicator extends HTTPCommunicator
{
	String url = "http://ec2-184-72-152-11.compute-1.amazonaws.com:80";
	
	public HttpResponse activatePlayer(String playerID, boolean makeActive)
	{	
		String getLevelMetadata;
		if(makeActive)
			getLevelMetadata = "/ra/games/1/players/"+playerID+"/activate";
		else
			getLevelMetadata = "/ra/games/1/players/"+playerID+"/deactivate";
		try{
			HttpResponse response = doPut(url, getLevelMetadata);
			return response;
		}
		catch(Exception e)
		{
		}
		return null;
	}
	
	public HttpResponse activateLevel(String levelID, boolean makeActive)
	{	
		String getLevelMetadata;
		if(makeActive)
			getLevelMetadata = "/ra/games/1/levels/"+levelID+"/activate";
		else
			getLevelMetadata = "/ra/games/1/levels/"+levelID+"/deactivate";
		try{
			HttpResponse response = doPut(url, getLevelMetadata);
			return response;
		}
		catch(Exception e)
		{
		}
		return null;
	}
	
	public HttpResponse deleteLevel(String levelID)
	{
		String getLevelMetadata = "/ra/games/1/levels/" + levelID;
		try{
			HttpResponse response = doDelete(url, getLevelMetadata);
			return response;
		}
		catch(Exception e)
		{
		}
		return null;
	}
	
	public HttpResponse createRandomLevel()
	{
		String getLevelMetadata = "/ra/games/1/levels/random";
		try{
			HttpResponse response = doPost(url, getLevelMetadata);
			return response;
		}
		catch(Exception e)
		{
		}
		return null;
	}
	
	public HttpResponse createLevel()
	{
		String getLevelMetadata = "/ra/games/1/levels/new";
		try{
			HttpResponse response = doPost(url, getLevelMetadata);
			return response;
		}
		catch(Exception e)
		{
		}
		return null;
	}
	
	public HttpResponse activateAllPlayers(boolean makeActive)
	{
		String getLevelMetadata;
		if(makeActive)
			getLevelMetadata = "/ra/games/1/activateAllPlayers";
		else
			getLevelMetadata = "/ra/games/1/deactivateAllPlayers";
		try{
			HttpResponse response = doPut(url, getLevelMetadata);
			return response;
		}
		catch(Exception e)
		{
		}
		return null;
	}
	
	public HttpResponse activateAllLevels(boolean makeActive)
	{
		String getLevelMetadata;
		if(makeActive)
			getLevelMetadata = "/ra/games/1/activateAllLevels";
		else
			getLevelMetadata = "/ra/games/1/deactivateAllLevels";
		try{
			HttpResponse response = doPut(url, getLevelMetadata);
			return response;
		}
		catch(Exception e)
		{
		}
		return null;
	}
	
	public HttpResponse requestMatch(String playerID)
	{
		String getLevelMetadata = "/ra/games/1/players/"+playerID+"/count/100/match";
		try{
			HttpResponse response = doPost(url, getLevelMetadata);
			return response;
		}
		catch(Exception e)
		{
		}
		return null;
	}
	
	public HttpResponse refuseMatch(String playerID)
	{
		String getLevelMetadata = "/ra/games/1/players/"+playerID+"/refused";
		try{
			HttpResponse response = doPut(url, getLevelMetadata);
			return response;
		}
		catch(Exception e)
		{
		}
		return null;
	}

	public HttpResponse setPriority(String levelID, int priority)
	{	
		String getLevelMetadata = "/ra/games/1/levels/"+levelID+"/priority/"+priority+"/set";
		try{
			HttpResponse response = doPut(url, getLevelMetadata);
			return response;
		}
		catch(Exception e)
		{
		}
		return null;
	}
	
	public HttpResponse searchForLevels(int count)
	{
		return searchForLevels(count, null);
	}
	
	//doesn't seem to work...
	public HttpResponse searchForLevels(int count, HttpEntity entity)
	{
		String getLevelMetadata = "/ra/games/1/levels/count/" + count + "/search";
		getLevelMetadata = "/ra/games/1/levels/count/10/search";
		try{
		//	String bar = "{\"parameter\":[{\"name\":\"param_one\",\"isRequired\":true,\"from\":5.5314183915768576,\"to\":5.531429454424704},{\"name\":\"param_two\",\"isRequired\":true,\"from\":0.8688698078309287,\"to\":0.8688715455722822},{\"name\":\"param_three\",\"isRequired\":true,\"from\":-37.28989792267633,\"to\":-37.28982334295506}],\"property\":[],\"tag\":[],\"label\":[],\"priority\":[],\"parentId\":[],\"predecessorId\":[]}";
		//	String bar1 = "{\"parameter\":[{\"name\":\"param_one\",\"isRequired\":true,\"from\":5.5314183915768576,\"to\":5.531429454424704},{\"name\":\"param_two\",\"isRequired\":true,\"from\":0.8688698078309287,\"to\":0.8688715455722822},{\"name\":\"param_three\",\"isRequired\":true,\"from\":-37.28989792267633,\"to\":-37.28982334295506}],\"property\":[],\"tag\":[],\"label\":[],\"priority\":[],\"parentId\":[],\"predecessorId\":[]}";
			
		//	String bar1 = "{parameter:[{name:param_two,isRequired:true,from:0.7665302026030788,to:0.7665317356650171},{name:param_one,isRequired:true,from:13.846440805352552,to:13.846468498261855},{name:param_three,isRequired:true,from:-22.86268968934822,to:-22.862643964014563}],property:[],tag:[],label:[],priority:[],parentId:[],predecessorId:[]}";
	//		entity = new StringEntity(bar1);
			HttpResponse response = doPost(url, getLevelMetadata, entity);
			return response;
		}
		catch(Exception e)
		{
		}
		return null;
	}
	
	public HttpResponse getLevelMetadata(String levelID)
	{
		String getLevelMetadata = "/ra/games/1/levels/" + levelID + "/metadata";
		try{
			HttpResponse response = doGet(url, getLevelMetadata);
			return response;
		}
		catch(Exception e)
		{
		}
		return null;
	}
	
	public HttpResponse getLevelStatusReport(String levelID)
	{
		String getLevelMetadata = "/ra/games/1/levels/" + levelID + "/active";
		try{
			HttpResponse response = doGet(url, getLevelMetadata);
			return response;
		}
		catch(Exception e)
		{
		}
		return null;	
	}
	
	public HttpResponse[] declareLevelMetadata(ArrayList<String> fileIDs, ArrayList<String> names) throws Exception
	{
		HttpResponse[] responses = new HttpResponse[fileIDs.size()];
		
		for(int i = 0; i< fileIDs.size(); i++)
			responses[i] = declareLevelMetadata(fileIDs.get(i), names.get(i));
		
		return responses;
	}
	
	public HttpResponse declareLevelMetadata(String fileID, String name) throws Exception
	{
		//declare level metadata
		String declareLevelMetadata = "/ra/games/1/levels/metadata";
		
		JSONObject levelJSONObj = new JSONObject();
		levelJSONObj.append("fileID", fileID);

		addMetadataToLevelObject(levelJSONObj, name);
		
		try{
			HttpEntity entity = new StringEntity(levelJSONObj.toString());
			HttpResponse response = doPost(url, declareLevelMetadata, entity);
			return response;
		}
		catch(Exception e)
		{
			
		}
		return null;
	}
	
	public HttpResponse[] setLevelMetadata(ArrayList<String> fileIDs, ArrayList<String> names) throws Exception
	{
		HttpResponse[] responses = new HttpResponse[fileIDs.size()];
		
		for(int i = 0; i< fileIDs.size(); i++)
			responses[i] = declareLevelMetadata(fileIDs.get(i), names.get(i));
		
		return responses;
	}
	
	public HttpResponse setLevelMetadata(String id, String fileID, String name) throws Exception
	{
		//declare level metadata
		String setLevelMetadata = "/ra/games/1/levels/metadata";
		
		JSONObject levelJSONObj = new JSONObject();
		levelJSONObj.append("fileID", fileID);
		levelJSONObj.append("ids", id);

		addMetadataToLevelObject(levelJSONObj, name);
		
		try{
			HttpEntity entity = new StringEntity(levelJSONObj.toString());
			HttpResponse response = doPut(url, setLevelMetadata, entity);
			return response;
		}
		catch(Exception e)
		{
			
		}
		return null;
	}
	
	protected void addMetadataToLevelObject(JSONObject obj, String name)
	{
		JSONObject levelMetadata = new JSONObject();
		
		levelMetadata.append("priority", 5);
		levelMetadata.append("comment", "comment");
		
		JSONObject param1 = new JSONObject();
		param1.append("name", "type");
		param1.append("value", "NullChecker");
		JSONObject param2 = new JSONObject();
		param2.append("name", "difficulty");
		param2.append("value", "5");
		
		levelMetadata.append("parameters", param1);
		levelMetadata.append("parameters", param2);
		
		JSONObject prop1 = new JSONObject();
		prop1.append("name", "boxes");
		prop1.append("value", "10");
		levelMetadata.append("properties", prop1);
		JSONObject prop2 = new JSONObject();
		prop2.append("name", "lines");
		prop2.append("value", "10");
		levelMetadata.append("properties", prop2);
		JSONObject prop3 = new JSONObject();
		prop3.append("name", "name");
		prop3.append("value", name);
		levelMetadata.append("properties", prop3);

		obj.put("metadata", levelMetadata);

	}
}
