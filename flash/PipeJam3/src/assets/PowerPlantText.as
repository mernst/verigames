package assets 
{
	/**
	 * ...
	 * @author ...
	 */
	public class PowerPlantText extends StringTableMTurk { 
		
		protected override function doLookup(key:int):String { 
			switch (key) { 
				case INTRO_VARIABLES: return "Power plants give out different types of power.\n Click and drag to match the power delivered.";
				case SELECTOR_UNLOCKED: return "New power type\n"+"unlocked! Change\n" +"power type by\n"+"clicking on one\n"+"of the power\n"+"    previews -->"
				case ELIMINATE_PARADOX: return "Power as many factories as you can!";
				case INTRO_SOLVER1_BRUSH:return "New magic power unlocked! The star power will automatically adjust the\nselected powertype to supply a number of factories.";
				case INTRO_SOLVER2_BRUSH:return "New magic power unlocked! The diamond power will automatically adjust the\nselected powertype to supply a number of factories.";
				case FUNCTION_SOLVER1_BRUSH:return "The star power will automatically adjust the\nselected powertype to supply a number of factories.\n Power as many factories as you can!";
				case FUNCTION_SOLVER2_BRUSH:return "The diamond power will automatically adjust the\nselected powertype to supply a number of factories.\n Power as many factories as you can!";
				case BOTH_BRUSHES_ENABLED:return  "New selector unlocked! The diamond power\nmay find different solutions from the star power.\nThe diamond power can run for a long time, click again if you need to stop it.";
				case INFORM_LIMITS:return "There is a limit to how many power plants you select. The numbers on the\npower types indicate how many you've selected and the selection limit.";
				case INTRO_SELECTION_AREAS:return "Different selection areas will create different solutions.\nSometimes many items need to change to power a factory.";
				case TIP_VARIABLE:return "Power plant";
				case TIP_CONSTRAINT:return "Factory";
				case TIP_PARADOX:return "Paradox";
				case TIP_PARADOX_CONSTRAINT:return "Factory\nwith\nparadox";
				case TIP_PARADOX_REMOVAL:return "To remove this paradox two others\nwould be created, so leaving this\nparadox is the optimal solution";
				case TIP_PARADOX_REMOVED: return "paradox\nremoved!";
				case APPRECIATE: return "Great work! The target score for this level was reached by\n" + "powering all the factories. Move on to the next level to learn more!";
				
			}
			return super.doLookup(key);
		}
	}

}