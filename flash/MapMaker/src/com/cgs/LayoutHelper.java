package com.cgs;


import java.text.SimpleDateFormat;
import java.util.Calendar;
import com.cgs.elements.*;


public class LayoutHelper
{	
	StringBuilder builder;
	
	public LayoutHelper()
	{

	}
	
	public void organizeNodes(Graph graph)
	{
		//lays out nodes where they should be, size and position
		//	based on input gxl file that gives size and relative positions
		Level level = null;
		try {
			for(int levelIndex = 0; levelIndex<graph.levels.size(); levelIndex++)
			{
				Calendar cal = Calendar.getInstance();
		    	cal.getTime();
		    	SimpleDateFormat sdf = new SimpleDateFormat("HH:mm:ss");
		    	System.out.println( "starting " + sdf.format(cal.getTime()) );
		    	
		    	level = graph.levels.get(levelIndex);
				level.layoutNodes();
	//			level.expandLevel();
	
					
					cal.getTime();
			    	SimpleDateFormat sdf1 = new SimpleDateFormat("HH:mm:ss:SSS");
				   	System.out.println( "done with " + levelIndex + " level at "+ sdf1.format(cal.getTime()) );
				    
			}
		}catch(Exception e)
		{
			System.out.println("level failed " + level.id);
		}
	}
}
