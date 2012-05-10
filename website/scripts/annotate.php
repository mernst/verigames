<?php

define(JAVA_PATH,'/homes/abstract/bdwalker/www/live/java/');
define(SCRIPT_PATH, '/homes/abstract/bdwalker/www/live/scripts/');
define(UPLOADS_DIRECTORY, '/homes/abstract/bdwalker/www/live/uploads/');
$id = $_GET["id"];	
$checker = $_GET["checker"];

//switch the script from infer to check
$checker = str_replace("infer", "check", $checker);

//change working path
chdir('/homes/abstract/bdwalker/www/live/uploads/'.$id);

if(createUpdatedXML($id, $checker)) {
    annotateAndCheck($checker);
  
}
  displayFiles($path, $id);
    
/*
 * Function that will create an updated inference file based on the results of the game. It accepts
 * two arguments, the path to the location of the java files and the path to where the script files
 * are located. If there is an error during the parsing process a file will be created in the directory
 * entitled jaif_parse_error.txt with the error results. Likewise, during the annotation process, if
 * an error is encountered than a file called annotate_error.txt will be created with the errors
 * encountered.
 */
function createUpdatedXML($id, $checker) {
    exec("cp ".SCRIPT_PATH."world.dtd ".UPLOADS_DIRECTORY.$id."/world.dtd 2> fail.txt");
    exec('/homes/abstract/bdwalker/jdk1.7.0/bin/java -cp '.JAVA_PATH.'verigames.jar verigames.utilities.JAIFParser '.UPLOADS_DIRECTORY.$id.'/updatedXML.xml '.
            './inference.jaif ./updatedInference.jaif 2> '.UPLOADS_DIRECTORY.$id.'/jaif_parse_error.txt');	
    if(file_exists("./updatedInference.jaif") &&  !file_exists("./inference-output")) 
	   return TRUE;
    else
       return FALSE;
}


function annotateAndCheck($checker) {
    $output = './inference-output';
    $input =  realpath('./updatedInference.jaif');
    $to_execute = '/homes/abstract/bdwalker/jdk1.7.0/bin/java  -Xbootclasspath/p:'.JAVA_PATH.'verigames.jar annotator.Main -d '.$output.
	     ' '.$input.' `find -name "*.java"` > annotate_error.txt 2>&1';
    exec('/homes/abstract/bdwalker/jdk1.7.0/bin/java  -Xbootclasspath/p:'.JAVA_PATH.'verigames.jar annotator.Main -d '.$output.
	     ' '.$input.' `find -name "*.java"` > annotate_error.txt 2>&1');	
}

/*
 * Function that will print the html to display for each of the .java files in the current
 * directory. This is function is required for the results on the results.php page to display.
 * It accepts the path to the upload directory and the guid of the specific folder to display
 * the results for. 
 */
function displayFiles($id) {
	$files = shell_exec("find ./inference-output/*.java ./inference-output/*/*.java");
	$files = explode("\n", $files);
	$full_path=('/uploads/'.$id.'/inference-output/');
	
	foreach($files as $file) {
		$file_array = explode("/", $file);
		$last = count($file_array) - 1;
		print("<input type=\"radio\" id=".$file." name=\"radio\"/><label ".
		      "for=".$file.">".$file_array[$last]."</label>");
	}
}
?>