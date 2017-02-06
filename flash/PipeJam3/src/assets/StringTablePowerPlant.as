package assets 
{
	public class StringTablePowerPlant extends StringTableMTurk { 
		
		protected override function doLookup(key:int):String { 
			switch (key) { 
				
				
				
				
				
				case INTRO_VARIABLES: return "Power plants can emit different types of energy: light and dark.\nClick and drag to select power plants.\nRelease the mouse to deploy engineers to change them.";
				case SELECTOR_UNLOCKED: return "New engineer type\nunlocked! Change\nengineer type by\nclicking on one\nof the engineer\n    previews -->"
				case ELIMINATE_PARADOX: return "Eliminate as many blackouts as you can!";
				case INTRO_SOLVER1_BRUSH:return "New engineer type unlocked! The star engineer will automatically adjust the\nselected power plants to reduce the overall number of blackouts.";
				case INTRO_SOLVER2_BRUSH:return "New engineer type unlocked! The diamond engineer will automatically adjust the\nselected power plants to reduce the overall number of blackouts.";
				case FUNCTION_SOLVER1_BRUSH:return "The star engineer will automatically adjust the\nselected power plants to reduce the overall number of blackouts.\nEliminate as many red blackouts as you can!";
				case FUNCTION_SOLVER2_BRUSH:return "The diamond engineer will automatically adjust the\nselected power plants to reduce the overall number of blackouts.\nEliminate as many red blackouts as you can!";
				case BOTH_BRUSHES_ENABLED:return  "New engineer unlocked! The diamond engineer\nmay find different solutions from the star engineer.\nThe diamond engineer can work for a long time; click again if you need to stop it.";
				case INFORM_LIMITS:return "There is a limit to how many power plants you can select. The numbers on the\nselection ring indicate how many you've selected and the selection limit.";
				case INTRO_SELECTION_AREAS:return "Different selections will create different solutions.\nSometimes many power plants need to change to eliminate a blackout.";
				case TIP_VARIABLE:return "Power plant";
				case TIP_CONSTRAINT:return "Factory";
				case TIP_PARADOX:return "Blackout";
				case TIP_PARADOX_CONSTRAINT:return "Factory\nwith\nblackout";
				case TIP_PARADOX_REMOVAL:return "To remove this blackout two others\nwould be created, so leaving this\nblackout is the best solution.";
				case TIP_PARADOX_REMOVED: return "Blackout\nremoved!";
				case APPRECIATE: return "Great work! The target score for this level was reached by\nremoving all the blackouts. Move on to the next level to learn more!";
				
			}
			return super.doLookup(key);
		}
	}

}