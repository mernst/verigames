import com.cgs.*;

/*
 * steps to get this working, and why you do each step:
 * 1) generate xml from 'the system'
 * 		reason - well duh...
 * 2) run this code passing the input and output file
 * 		java -jar MapMaker.jar world.xml iworld.dot (i-world for intermediate dot format? You can choose your own name.)
 * 		This produces a dot file that has the size of the nodes defined
 * 3) run dot and the gv to gxl converter (two steps, as sometimes the gv file creation happens too slow, and 
 * 			gv2gxl can't find it
 * 		dot iworld.dot -Tgv -oiworld.gv 
 *		gv2gxl.exe  iworld.gv > iworld.gxl
 * 		This produces a graph file that has relative X and Y positioning for the nodes
 * 3a) if you want to see the intermediate graph as a jpg
 * 		dot -Tjpg -o world.jpg world.dot
 * 4) run this code again, passing the gxl file as the argument, and a new dot output file
 * 		java -jar MapMaker.jar iworld.gxl world.gxl 
 * 			(The code uses the file type as a switch, so this needs to be a gxl file, and the above needs to be a xml file)
 * 
 * What that produces is a gxl file that I've calculated the edge paths for.
 * 
 * What follows is wishful thinking if dot could actually take a file with preset node height/widths, and produce nice edges for. (Doesn't seem
 * 	like too much to ask, does it? It takes files, it produces nice edges, why does it HAVE to change node positions? Neato and fdp don't change
 *  node positions if you tell them not too, but they don't produce nice edges....)
 *  
 * 		Using the relative positioning and the size, move things around to be grid-like.
 * 			it would be great if I can specify where the edges connect also, but dot does some odd things I haven't completely figured out
 * 5) run dot again, this time with flags that tell it to respect node positions
 * 		dot world.dot -Kneato -n -Tgv -oworld.gv | gv2gxl.exe  world.gv > world.gxl
 * 			also might need to do in two steps
 * 		Now that we have absolute size/positions, get dot to draw in edges that I can follow.
 * 			(again, these might not be perfect as arrows tend to cluster and not get evenly distributed - we should work on that.)
 */
public class MapMaker {
	
	static FileHandler handler = null;

	/**
	 * @param args
	 */
	public static void main(String[] args) {
		
		  try{
			  if(args[0].indexOf(".xml") != -1)
				{
					handler = new ClusterFinder(args[0], args[1]);
				}
				else if(args[0].indexOf(".gxl") != -1)
				{
					handler = new LayoutHelper(args[0], args[1]);
				}

			  handler.runSaxParser();
			  handler.organizeNodes();
			  handler.addMapFileStart();
			  handler.writeFileMain();
			  handler.addMapFileEnd();
			  
			  handler.writeMapFile();

		  }catch (Exception e){//Catch exception if any
			  System.err.println("Error: " + e.getMessage());
			  handler.writeMapFile();
		  }
	}
	

}
