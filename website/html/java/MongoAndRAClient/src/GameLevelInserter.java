import java.io.File;
import java.io.FilenameFilter;
import com.mongodb.DB;
import com.mongodb.Mongo;

/*
 * The Plan:
 * 
 * Create a level in the RA. This contains the official levelID.
 * 
 * Add the three files. The base xml, the starter layout, the first constraints file. The latter two contain a xmlID equal to
 * the base xml _id, plus a 'L' or 'C' at the end, depending on whether it's a layout or constraints file.
 * 
 * Create a level object in the database. This contains a levelId that matches the RA levelID, and then file IDs for
 * the three previously added files to use on initial load. (NOTE: you need to leave a field called levelID, as the DB
 * is constrained to have unique levelId:gameId strings. Since we don't have gameId, we just need to provide unique levelId strings to make that work.)
 * 
 * To start a game, the user will be presented a list of levels ( = a list of constraint files for various levels). The user will
 * choose one, and then we will: 1) Retrieve the mongo level associated with that by matching the ra object levelID with the mongo level
 * gameLevelID. 2) From that we will get the various file IDs and retrieve the associated files. 
 * 
 * To add additional layouts, we just need to create a file with the xmlID of the base xml file.
 * 
 * To add additional constraint files, we 1) create a new RA level. 2) store the constraints file in the database, and 3) create a new mongo level
 * using that information, the base xml file id, and some layout file id.
 * 
 * When choosing a specific layout, we will present a list of 'filename's that was found by searching for the xmlID+'L' id.
 * (We could do the same when someone expresses a liking for a specific graph, then we could search for other constraints files.)
 */
public class GameLevelInserter {
	static String mongoAddress = "flowjam.verigames.com";

	/**
	 * @param args
	 */
	public static void main(String[] args) {
	       Mongo mongo = null;
		try {
			mongo = new Mongo( mongoAddress );
	        String dbName = "gameapi";
	        DB db = mongo.getDB( dbName );
	        
	        File dir = new File(args[0]);
	        File difficultyFile = new File(args[1]);
	        MongoFileInserter fileInserter = new MongoFileInserter(db);
        	RALevelInserter raLevelInserter = new RALevelInserter();
        	MongoLevelInserter mongoLevelInserter = new MongoLevelInserter(db, difficultyFile);
        	
        	String raLevelID = "3";
        	String priorityLevel = "5";
        	boolean activate = false;
        	if(args.length>3)
        	{
	        	//raLevelID = args[2];
	        	priorityLevel = args[2];
	        	activate = Boolean.parseBoolean(args[3]);
        	}
        	
	        if(dir.isDirectory())
	        {
	        	File[] files = dir.listFiles(new FilenameFilter() {
	        	    public boolean accept(File directory, String fileName) {
	        	        return fileName.endsWith(".zip") 
	        	        && !fileName.endsWith("Layout.zip") 
	        	        && !fileName.endsWith("Constraints.zip");
	        	    }});
	        	
	        	for(int i=0; i<files.length; i++)
	        	{
	        		File xmlFile = files[i];
	        		System.out.println("File is : " + xmlFile.getName());
	        		fileInserter.addLevelFiles(xmlFile);
		        	raLevelID = raLevelInserter.createNewLevel();
		        	System.out.println("Level ID is : " + raLevelID);
		        	int index = xmlFile.getName().lastIndexOf('.');
		        	String fileName = xmlFile.getName().substring(0, index);
		        	mongoLevelInserter.addLevel(raLevelID, fileInserter, fileName);
		        	raLevelInserter.setPriority(raLevelID, Integer.parseInt(priorityLevel));
		        	if(activate)
		        		raLevelInserter.activateLevel(raLevelID, activate);
	        	}
	        }
	        else
	        {
	        	File file = dir;
	        	//This section isn't equivalent to passing in a directory, as this is for single files pushed on the website
	        	System.out.println("File is : " + file.getName());
        		fileInserter.addLevelFiles(file);

	        	int index = file.getName().lastIndexOf('.');
	        	String fileName = file.getName().substring(0, index);
	        	mongoLevelInserter.addLevel(raLevelID, fileInserter, fileName);
	        	raLevelInserter.setPriority(raLevelID, Integer.parseInt(priorityLevel));
	        	if(activate)
	        		raLevelInserter.activateLevel(raLevelID, activate);
	        }
	        
		} catch (Exception e) {
			if(mongo != null)
				mongo.close();
			e.printStackTrace();
		}

	}

}
