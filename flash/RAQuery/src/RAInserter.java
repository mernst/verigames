import java.util.ArrayList;

import org.apache.http.HttpResponse;


public class RAInserter {
	
	public static ArrayList<String> idList = new ArrayList<String>();
	
	public static ArrayList<String> nameList = new ArrayList<String>();
	
	public static void main(String[] args)
	{
		try{
			idList.add("51815bcfa8e027680cbd21b1");
			nameList.add("Seth's Level");
			
			idList.add("51815bc3a8e027680cbd21ab");
			nameList.add("Simple Level");
			
			RACommunicator raCom = new RACommunicator();
			HttpResponse[] responses = new HttpResponse[idList.size()];
			for(int i = 0; i<idList.size(); i++)
			{
				HttpResponse response = raCom.createLevel();
				String levelID = 
				responses[i] = raCom.setLevelMetadata(levelID, idList.get(i), nameList.get(i));
				raCom.printResponseAndEntity(responses[i]);
			}
			
			for(int i = 0; i<responses.length; i++)
			{
				
			}
		}
		catch(Exception e)
		{
			
		}
	}

}
