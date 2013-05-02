

import org.apache.http.HttpResponse;

public class RATestBed {

	public static void main(String[] args) {

		try{
			RACommunicator raCommunicator = new RACommunicator();
			HttpResponse response = null;
			//add levels to the RA, and set some metadata
			//adding metadata for the levels also creates them...
		//	String appRequest = "/ra/games/1/levels/517994e7a8e0f633776c98ed/new";
		//	String sethRequest = "/ra/games/1/levels/517994e7a8e0f633776c98f3/new";	
		//	String levelPriority = "/ra/games/1/levels/{levelId}/priority/{priority}/set";
		//	HttpResponse response = getLevelMetadata("5176e6dbe4b03743be6d8d6c");
	
		// response = getLevelMetadata("517aca9be4b03743be6d8dad");
		//	HttpResponse response = getLevelMetadata("515b4cce49428925e4bd86e9");
			
			//search  params??
//			JSONObject levelMetadataObj = new JSONObject();
//			JSONObject levelMetadata = new JSONObject();
//			levelMetadata.append("name", "priority");
//			levelMetadata.append("isRequired", "true");
//			levelMetadata.append("from", 0.0);
//			levelMetadata.append("to", 10.0);
//			levelMetadataObj.append("prority", levelMetadata);
//			String foo = "{\"priority\" : { \"name\" : \"priority\", \"isRequired\" : true, \"from\" : 0.0, \"to\" : 100.0}}";
//
//			HttpEntity entity = new StringEntity(foo);//levelMetadataObj.toString());
			
			//Levels
			//517aca9be4b03743be6d8dad
			//players
			//51365e65e4b0ad10f4079c88
			
		//	raCommunicator.printResponseAndEntity(raCommunicator.searchForLevels(0));
					raCommunicator.printResponseAndEntity(raCommunicator.setPriority("5181402de4b03743be6d8f66", 11));
					raCommunicator.printResponseAndEntity(raCommunicator.setPriority("51815c35e4b03743be6d8f7f", 11));
					raCommunicator.printResponseAndEntity(raCommunicator.activateLevel("5181402de4b03743be6d8f66", true));
					raCommunicator.printResponseAndEntity(raCommunicator.activateLevel("51815c35e4b03743be6d8f7f", true));
				//setLevelMetadata("517994e7a8e0f633776c98ed");
			//createRandomLevel();
//			response = requestMatch("51365e65e4b0ad10f4079c88");
//			JSONObject obj = printResponse(response);
//	//		System.out.println(response.toString());
//			//JSONObject obj = getJSONFromEntity(response);
//			JSONArray arr = obj.getJSONArray("matches");
//			for(int i = 0; i< arr.length(); i++)
//			{
//				String val = arr.getJSONObject(i).getString("levelId");
//				if(val != null)
//				{
//					System.out.println(val);
//					printResponse(deleteLevel(val));
//					//printResponse(getLevelMetadata(val));
//				}
//			}
		//	printResponse(refuseMatch("51365e65e4b0ad10f4079c88"));
		//	printResponse(searchForLevels(10));
//			System.out.println("create");
//			raCommunicator.printResponseAndEntity(raCommunicator.createLevel("517994e7a8e0f633776c98f3"));
//			System.out.println("activate");
//			raCommunicator.printResponseAndEntity(raCommunicator.activateLevel("517994e7a8e0f633776c98f3", true));
//			System.out.println("set");
//			raCommunicator.printResponseAndEntity(raCommunicator.setLevelMetadata("517994e7a8e0f633776c98f3"));
//			System.out.println("get");
//			raCommunicator.printResponseAndEntity(raCommunicator.getLevelMetadata("517994e7a8e0f633776c98f3"));
//			raCommunicator.printResponse(raCommunicator.activateAllLevels(true));
		//	printResponse(activateAllPlayers(true));
		//	printResponse(activateAllPlayers(false));
		//	printResponse(activatePlayer("515f58b4e4b03743be6d8d65", true));
			
		}
		catch(Exception e)
		{
			System.out.println(e);
		}
	}
}