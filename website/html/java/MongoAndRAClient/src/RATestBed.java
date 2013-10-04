import org.apache.http.HttpResponse;

import com.cra.csfvRaRest.PrincipalType;
import com.cra.csfvRaRest.schemas.responses.SearchLevelsResponse;

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
			
//			SearchLevelsResponse sr = ra.searchForLevels(0);
//			ra.printResponseAndEntity(ra.searchForLevels(0));
//					ra.printResponseAndEntity(ra.setPriority("5181402de4b03743be6d8f66", 11));
//					ra.printResponseAndEntity(ra.setPriority("51815c35e4b03743be6d8f7f", 11));
//					ra.printResponseAndEntity(ra.activateLevel("5181402de4b03743be6d8f66", true));
//					ra.printResponseAndEntity(ra.activateLevel("51815c35e4b03743be6d8f7f", true));
				//setLevelMetadata("517994e7a8e0f633776c98ed");
			//createRandomLevel();
//			response = requestMatch("51365e65e4b0ad10f4079c88");
//			JSONObject obj = printResponse(response);
//	//		System.out.println(response.toString());
			//JSONObject obj = getJSONFromEntity(sr.toString());
			//JSONArray arr = obj.getJSONArray("ids");
//			for(String id : sr.ids)
			//for(int i = 0; i< arr.length(); i++)
			{
//				String val = arr.getJSONObject(i).getString("levelId");
//				if(val != null)
//				{
//				if(!id.equals("521692a9e4b06c4c132c473a"))
//				{
//					System.out.println(id);
//					ra.printResponseAndEntity(ra.deleteLevel(id));
//				}
//					//printResponse(getLevelMetadata(val));
//				}
			}
		//	printResponse(refuseMatch("51365e65e4b0ad10f4079c88"));
		//	printResponse(searchForLevels(10));
//			System.out.println("create");
//			ra.printResponseAndEntity(ra.createLevel("517994e7a8e0f633776c98f3"));
//			System.out.println("activate");
//			ra.printResponseAndEntity(ra.activateLevel("521692a9e4b06c4c132c473a", true));
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
			
			ra.activateLevel("524ee8a2e4b04c664619fa36", false);
			ra.activateLevel("524ee8a2e4b04c664619fa39", false);
			ra.activateLevel("524ee8a3e4b04c664619fa3c", false);
			ra.activateLevel("524ee8a4e4b04c664619fa3f", false);
			ra.activateLevel("524ee8a4e4b04c664619fa42", false);
			ra.activateLevel("524ee8a5e4b04c664619fa45", false);
			ra.activateLevel("524ee8a5e4b04c664619fa48", false);
			ra.activateLevel("524ee8a6e4b04c664619fa4b", false);
			ra.activateLevel("524ee8a6e4b04c664619fa4e", false);
			ra.activateLevel("524ee8a7e4b04c664619fa51", false);
			ra.activateLevel("524ee8a7e4b04c664619fa54", false);
			ra.activateLevel("524ee8a8e4b04c664619fa57", false);
			ra.activateLevel("524ee8a8e4b04c664619fa5a", false);
			ra.activateLevel("524ee8a9e4b04c664619fa5d", false);
			ra.activateLevel("524ee8a9e4b04c664619fa60", false);
			ra.activateLevel("524ee8aae4b04c664619fa63", false);
			ra.activateLevel("524ee8aae4b04c664619fa66", false);
			ra.activateLevel("524ee8abe4b04c664619fa69", false);
			ra.activateLevel("524ee8abe4b04c664619fa6c", false);
			ra.activateLevel("524ee8ace4b04c664619fa6f", false);
			ra.activateLevel("524ee8ace4b04c664619fa72", false);
			ra.activateLevel("524ee8ade4b04c664619fa75", false);
			ra.activateLevel("524ee8ade4b04c664619fa78", false);
			ra.activateLevel("524ee8ade4b04c664619fa7b", false);
			ra.activateLevel("524ee8aee4b04c664619fa7e", false);
			ra.activateLevel("524ee8aee4b04c664619fa81", false);
			ra.activateLevel("524ee8afe4b04c664619fa84", false);
			ra.activateLevel("524ee8afe4b04c664619fa87", false);
			ra.activateLevel("524ee8b0e4b04c664619fa8a", false);
			ra.activateLevel("524ee8b0e4b04c664619fa8d", false);
			ra.activateLevel("524ee8b1e4b04c664619fa90", false);
			ra.activateLevel("524ee8b1e4b04c664619fa93", false);
			ra.activateLevel("524ee8b2e4b04c664619fa96", false);
			ra.activateLevel("524ee8b2e4b04c664619fa99", false);
			ra.activateLevel("524ee8b3e4b04c664619fa9c", false);
			ra.activateLevel("524ee8b3e4b04c664619fa9f", false);
			ra.activateLevel("524ee8b4e4b04c664619faa2", false);
			ra.activateLevel("524ee8b4e4b04c664619faa5", false);
			ra.activateLevel("524ee8b5e4b04c664619faa8", false);
			ra.activateLevel("524ee8b5e4b04c664619faab", false);
			ra.activateLevel("524ee8b5e4b04c664619faae", false);
			ra.activateLevel("524ee8b6e4b04c664619fab1", false);
			ra.activateLevel("524ee8b6e4b04c664619fab4", false);
			ra.activateLevel("524ee8b7e4b04c664619fab7", false);
			ra.activateLevel("524ee8b7e4b04c664619faba", false);
			ra.activateLevel("524ee8b8e4b04c664619fabd", false);
			ra.activateLevel("524ee8b8e4b04c664619fac0", false);
			ra.activateLevel("524ee8b9e4b04c664619fac3", false);
			ra.activateLevel("524ee8b9e4b04c664619fac6", false);
			ra.activateLevel("524ee8bae4b04c664619fac9", false);
			ra.activateLevel("524ee8bae4b04c664619facc", false);
			ra.activateLevel("524ee8bbe4b04c664619facf", false);
			ra.activateLevel("524ee8bbe4b04c664619fad2", false);
			ra.activateLevel("524ee8bbe4b04c664619fad5", false);
			ra.activateLevel("524ee8bce4b04c664619fad8", false);
			ra.activateLevel("524ee8bce4b04c664619fadb", false);
			ra.activateLevel("524ee8bde4b04c664619fade", false);
			ra.activateLevel("524ee8bde4b04c664619fae1", false);
			ra.activateLevel("524ee8bee4b04c664619fae4", false);
			ra.activateLevel("524ee8bee4b04c664619fae7", false);
			ra.activateLevel("524ee8bfe4b04c664619faea", false);
			ra.activateLevel("524ee8bfe4b04c664619faed", false);
			ra.activateLevel("524ee8c3e4b04c664619faf0", false);
			ra.activateLevel("524ee8c3e4b04c664619faf3", false);
			ra.activateLevel("524ee8c3e4b04c664619faf6", false);
			ra.activateLevel("524ee8c4e4b04c664619faf9", false);
			ra.activateLevel("524ee8c4e4b04c664619fafc", false);
			ra.activateLevel("524ee8c5e4b04c664619faff", false);
			ra.activateLevel("524ee8c5e4b04c664619fb02", false);
			ra.activateLevel("524ee8c6e4b04c664619fb05", false);
			ra.activateLevel("524ee8c6e4b04c664619fb08", false);
			ra.activateLevel("524ee8c7e4b04c664619fb0b", false);
			ra.activateLevel("524ee8c7e4b04c664619fb0e", false);
			ra.activateLevel("524ee8c8e4b04c664619fb11", false);
			ra.activateLevel("524ee8c8e4b04c664619fb14", false);
			ra.activateLevel("524ee8c8e4b04c664619fb17", false);
			ra.activateLevel("524ee8c9e4b04c664619fb1a", false);
			ra.activateLevel("524ee8c9e4b04c664619fb1d", false);
			ra.activateLevel("524ee8cae4b04c664619fb20", false);
			ra.activateLevel("524ee8cae4b04c664619fb23", false);
			ra.activateLevel("524ee8cbe4b04c664619fb26", false);
			ra.activateLevel("524ee8cbe4b04c664619fb29", false);
			ra.activateLevel("524ee8cce4b04c664619fb2c", false);
			ra.activateLevel("524ee8cce4b04c664619fb2f", false);
			ra.activateLevel("524ee8cde4b04c664619fb32", false);
			ra.activateLevel("524ee8cde4b04c664619fb35", false);
			ra.activateLevel("524ee8cde4b04c664619fb38", false);
			ra.activateLevel("524ee8cee4b04c664619fb3b", false);
			ra.activateLevel("524ee8cee4b04c664619fb3e", false);
			ra.activateLevel("524ee8cfe4b04c664619fb41", false);
			ra.activateLevel("524ee8cfe4b04c664619fb44", false);
			ra.activateLevel("524ee8d0e4b04c664619fb47", false);
			ra.activateLevel("524ee8d0e4b04c664619fb4a", false);
			ra.activateLevel("524ee8d1e4b04c664619fb4d", false);
			ra.activateLevel("524ee8d1e4b04c664619fb50", false);
			ra.activateLevel("524ee8d1e4b04c664619fb53", false);
			ra.activateLevel("524ee8d2e4b04c664619fb56", false);
			ra.activateLevel("524ee8d2e4b04c664619fb59", false);
			ra.activateLevel("524ee8d3e4b04c664619fb5c", false);
			ra.activateLevel("524ee8d3e4b04c664619fb5f", false);
			ra.activateLevel("524ee8d4e4b04c664619fb62", false);
			ra.activateLevel("524ee8d4e4b04c664619fb65", false);
			ra.activateLevel("524ee8d5e4b04c664619fb68", false);
			ra.activateLevel("524ee8d5e4b04c664619fb6b", false);
			ra.activateLevel("524ee8d5e4b04c664619fb6e", false);
			ra.activateLevel("524ee8d6e4b04c664619fb71", false);
			ra.activateLevel("524ee8d6e4b04c664619fb74", false);
			ra.activateLevel("524ee8d7e4b04c664619fb77", false);
			ra.activateLevel("524ee8d7e4b04c664619fb7a", false);
			ra.activateLevel("524ee8d8e4b04c664619fb7d", false);
			ra.activateLevel("524ee8d8e4b04c664619fb80", false);
			ra.activateLevel("524ee8d9e4b04c664619fb83", false);
			ra.activateLevel("524ee8d9e4b04c664619fb86", false);
			ra.activateLevel("524ee8dae4b04c664619fb89", false);
			ra.activateLevel("524ee8dae4b04c664619fb8c", false);
			ra.activateLevel("524ee8dae4b04c664619fb8f", false);
			ra.activateLevel("524ee8dbe4b04c664619fb92", false);

//
//			ra.printResponseAndEntity(ra.setPriority("523b2c7de4b08aff27a273c1", 10));
//			ra.printResponseAndEntity(ra.setPriority("5238c53de4b08aff27a27396", 10));
//			ra.printResponseAndEntity(ra.setPriority("5238c53ee4b08aff27a27399", 10));
//			ra.printResponseAndEntity(ra.setPriority("5238c53ee4b08aff27a2739c", 10));
//			ra.printResponseAndEntity(ra.activateAllAgents(PrincipalType.LEVEL));

//			ra.printResponseAndEntity(ra.setPriority("5238c53ce4b08aff27a27390", 10));
//			ra.printResponseAndEntity(ra.setPriority("51fa8e49e4b0a12f02c4c9fb", 0));
//			ra.printResponseAndEntity(ra.setPriority("51faab87e4b0a12f02c4ca08", 0));
//		
//			ra.printResponseAndEntity(ra.activateLevel("523b2c7de4b08aff27a273c1", false));
//			ra.printResponseAndEntity(ra.activateLevel("5238c53de4b08aff27a27396", true));
//			ra.printResponseAndEntity(ra.activateLevel("5238c53ee4b08aff27a27399", true));
//			ra.printResponseAndEntity(ra.activateLevel("5238c53ee4b08aff27a2739c", true));
//			ra.printResponseAndEntity(ra.activateLevel("5238c53ce4b08aff27a27390", true));
//			ra.printResponseAndEntity(ra.activateLevel("5227af80e4b06c4c132c7333", true));
//			ra.activateLevel("524ee8dbe4b04c664619fb92", true);
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
			
			ra.getReport();
			ra.getVersion();
//			ra.printResponseAndEntity(ra.requestMatch("51e5b3460240288229000026", 10));
//			ra.printResponseAndEntity(ra.refuseMatches("51e5b3460240288229000026"));

		}
		catch(Exception e)
		{
			System.out.println(e);
		}
	}
}