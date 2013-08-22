import org.apache.http.HttpResponse;

import com.cra.csfvRaRest.PrincipalType;

public class RATestBed {

	public static void main(String[] args) {

		try{
			RA ra = new RA();
			HttpResponse response = null;
			//add levels to the RA, and set some metadata
			//adding metadata for the levels also creates them...
		//	String appRequest = "/ra/games/1/levels/517994e7a8e0f633776c98ed/new";
		//	String sethRequest = "/ra/games/1/levels/517994e7a8e0f633776c98f3/new";	
		//	String levelPriority = "/ra/games/1/levels/{levelId}/priority/{priority}/set";
		//	HttpResponse response = getLevelMetadata("5176e6dbe4b03743be6d8d6c");
	
		// response = getLevelMetadata("517aca9be4b03743be6d8dad");
		//	HttpResponse response = getLevelMetadata("515b4cce49428925e4bd86e9");
//			ra.createLevel();
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
			
		//	ra.printResponseAndEntity(ra.searchForLevels(0));
//					ra.printResponseAndEntity(ra.setPriority("5181402de4b03743be6d8f66", 11));
//					ra.printResponseAndEntity(ra.setPriority("51815c35e4b03743be6d8f7f", 11));
//					ra.printResponseAndEntity(ra.activateLevel("5181402de4b03743be6d8f66", true));
//					ra.printResponseAndEntity(ra.activateLevel("51815c35e4b03743be6d8f7f", true));
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
//			ra.printResponseAndEntity(ra.createLevel("517994e7a8e0f633776c98f3"));
//			System.out.println("activate");
//			ra.printResponseAndEntity(ra.activateLevel("51815c35e4b03743be6d8f7f", true));
//			System.out.println("set");
//			ra.printResponseAndEntity(ra.setLevelMetadata("517994e7a8e0f633776c98f3"));
//			System.out.println("get");
//			ra.printResponseAndEntity(ra.getLevelMetadata("517994e7a8e0f633776c98f3"));
//			ra.printResponse(ra.activateAllLevels(true));
		//	printResponse(activateAllPlayers(true));
		//	printResponse(activateAllPlayers(false));
		//	printResponse(activatePlayer("515f58b4e4b03743be6d8d65", true));
			
			
//			ra.deleteLevel("51965836e4b0615b7829e506").toString();
//			ra.deleteLevel("5196584ae4b0615b7829e508").toString();
//			ra.deleteLevel("5196584fe4b0615b7829e50a").toString();
//			
//			ra.deleteLevel("51965a4fe4b0615b7829e50f").toString();
//			ra.deleteLevel("51965809e4b0615b7829e4fe").toString();
//			ra.deleteLevel("51965810e4b0615b7829e500").toString();
//			ra.deleteLevel("5196581de4b0615b7829e502").toString();
//			
//			ra.printResponseAndEntity(ra.deactivateAllAgents(PrincipalType.LEVEL));
//			ra.printResponseAndEntity(ra.deleteLevel("51ecbdfde4b0a12f02c4c88a"));
//			ra.printResponseAndEntity(ra.deleteLevel("51ecbdfee4b0a12f02c4c88c"));
//			ra.printResponseAndEntity(ra.deleteLevel("51ecbdfee4b0a12f02c4c88e"));
//			ra.printResponseAndEntity(ra.deleteLevel("51ecbdffe4b0a12f02c4c890"));
//			ra.printResponseAndEntity(ra.deleteLevel("51ec960ae4b0a12f02c4c852"));
//			ra.printResponseAndEntity(ra.deleteLevel("51ec960be4b0a12f02c4c854"));
//			ra.printResponseAndEntity(ra.deleteLevel("51ec960ce4b0a12f02c4c856"));
//			ra.printResponseAndEntity(ra.deleteLevel("51ec960ce4b0a12f02c4c858"));
//			ra.deleteLevel("51965a51e4b0615b7829e510").toString();
//			ra.deleteLevel("51965a54e4b0615b7829e511").toString();
//
//			ra.printResponseAndEntity(ra.setPriority("51ecd34be4b0a12f02c4c89c", 10));
//			ra.printResponseAndEntity(ra.setPriority("51ecd34ce4b0a12f02c4c89e", 10));
//			ra.printResponseAndEntity(ra.setPriority("51ecd34ce4b0a12f02c4c8a0", 10));
//			ra.printResponseAndEntity(ra.setPriority("51ecd34de4b0a12f02c4c8a2", 10));
			ra.printResponseAndEntity(ra.activateAllAgents(PrincipalType.LEVEL));

//			ra.setPriority("519cfae3e4b0615b7829e519", 10);
//		
//			ra.printResponseAndEntity(ra.activateLevel("51ce2403a8e0a34d75516858", true));
//			ra.activateLevel("519cfb31e4b0615b7829e529", true);
//			ra.activateLevel("519cfae3e4b0615b7829e519", true);
			
//			ra.printResponseAndEntity(ra.refreshLevel("51cb3240e4b0fa95a28f6ceb"));
//			ra.printResponseAndEntity(ra.refreshLevel("5182d9b7e4b0615b7829e452"));
//			ra.printResponseAndEntity(ra.refreshLevel("5182d9bee4b0615b7829e454"));
//			
//			
//			ra.printResponseAndEntity(ra.createPrincipal(PrincipalType.LEVEL));
//			ra.printResponseAndEntity(ra.agentExists("51e5b3460240288229000026", PrincipalType.PLAYER));
//			ra.printResponseAndEntity(ra.activateAgent("51e5b3460240288229000026", true));
//			ra.printResponseAndEntity(ra.createExistingPrincipal(PrincipalType.PLAYER, "51e5b3460240288229000026"));
//			ra.printResponseAndEntity(ra.activateAgent("51e5b3460240288229000026", true));
//			ra.printResponseAndEntity(ra.deactivateAllAgents(PrincipalType.LEVEL));
//			ra.printResponseAndEntity(ra.activateLevel("51d322c5e4b0fa95a28f6d09", false));
//			ra.printResponseAndEntity(ra.activateLevel("51d322c5e4b0fa95a28f6d09", true));
//			ra.printResponseAndEntity(ra.refuseMatches("51e5b3460240288229000026"));
//			ra.printResponseAndEntity(ra.activateAgent("51ca04c81a0b4f4809000037", true));
//			ra.agentExists("51cb6fc7ddfe66b65d000021", PrincipalType.PLAYER);
			
//			ra.getReport();
//			ra.getVersion();
			ra.printResponseAndEntity(ra.requestMatch("51ca04c81a0b4f4809000037", 10));
			ra.printResponseAndEntity(ra.refuseMatches("51ca04c81a0b4f4809000037"));

		}
		catch(Exception e)
		{
			System.out.println(e);
		}
	}
}