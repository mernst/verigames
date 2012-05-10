<?php
/*
* 
*/


//constants
define("FILE_KEY", 'Filedata');
define("DIRECTORY", realpath("../uploads/"));
define("INFERENCE_LOC", "../scripts/inference.jaif");
define("WORLD_XML_LOC", "../scripts/World.xml");
define("VERIGAMES_JAR", "../java/verigames.jar");
define("COMPILE_OUTPUT", "compile_output.txt");
define("XML_ERROR", "xml_error.txt");
define("XML_LOG", "xml_creation_log.txt");
define("MAX_SIZE", 10485760);

/*
 * Parses the information sent from the ajax request.  If 
 * a request for a particular function is passed then that
 * function will be executed on the folder with the passed
 * guid identifier.  If no argument for a function was passed
 * then it is assumed that a file upload operation is being
 * performed and will attempt to move any files sent to the
 * server. 
 */
if(isset($_REQUEST["function"])) {
	$function = $_REQUEST["function"];
	$guid = $_REQUEST["guid"];
	$script = FALSE;
	if(isset($_REQUEST["script"]))
		$script = $_REQUEST["script"];
	//check for particular function
	if(!strcmp($function, "compile")) {
		$result = checkFileValidity($guid);
	} else if (!strcmp($function, "xml") && $script) {
		$result = createXMLFile($guid, $script);
	} else if (!strcmp($function, "cleanup")) {
		cleanup($guid, FALSE);
		$result = 1;
	} else if (!strcmp($function, "unzip")) {
		$result = unzipFiles($guid);
	} else if (!strcmp($function, "cleanup_all")) {
	   cleanup($guid, TRUE);
	   $result = "all_removed";
	}
	
	//respond with success or the location of the error file
	if($result == 1)
		print("SUCCESS");
	else { 
		print($result);
	}
} else {  
	$result = moveFilesTest();
	if(!$result)
	   print("Error moving files");
}

function moveFilesTest() {
	$response = TRUE;
	$tempFile = $_FILES['Filedata']['tmp_name'];

	$targetPath = DIRECTORY.$_REQUEST['folder']."/";
	print($targetPath);
	$targetFile =  $targetPath . $_FILES['Filedata']['name'];
	if(!file_exists($targetPath)) {
		if(!mkdir($targetPath)) {
			$response = FALSE;
		}
	}

	if(!move_uploaded_file($tempFile,$targetFile)) {
		$response = FALSE;
	}
	
    return $response;
}
	

/*
* Function that will unzip the .zip file the user uploaded. Function will call the unix
* unzip utility and output all the files to the users unique folder determined by the 
* $id parameter passed.  The $id parameter should be a unique guid.  The function will
* print the status of the unzipping ot the user in the format of an html table row. 
*/
function unzipFiles($id) {
	$path = DIRECTORY."/".$id."/";
	if(file_exists($path)) {
	   $handle = popen('unzip -o `find '.$path.' -name "*.zip"` -d '.$path, 'r');
	   pclose($handle);
	   return 1;
	} else
	   return "File or directory does not exist!";
		
}


/*
* Function to confirm if the .java files uploaded are valid and will compile.  It
* will run the javac Java compiler on each of the .java files uploaded by the user. 
* All the javac error output is saved in a file called output.txt in the users folder.
* If the folder is empty after the compile process then they compiled successfully, otherwise
* the compile process failed and it will display the error output to the user. Accepts
* a parameter $id, that represents the users unique folder guid. 
*/
function checkFileValidity($id){
	$path = DIRECTORY."/".$id;

	system('javac -Xlint:none -classpath .:'. VERIGAMES_JAR .' `find '.
	       $path.' -name "*.java"` 2> '.$path. '/'. COMPILE_OUTPUT);
	
	
	//display compile status
	return checkErrorOutput($path, COMPILE_OUTPUT);
}

/*
* Function creates the xml file that will be used with the flash game files.  It depends on the
* verigames.sh script file.  It will copy over the World.xml and the inference.jaif file created
* by the verigames.sh file.  It will return a 1 if the file was created successfully, otherwise
* it will return a 0. 
*/
function createXMLFile($id, $script) {
	$path = DIRECTORY."/".$id;
	//This needs to be changed, need to redirect file output
	$command = 'sh ../scripts/'. $script .' `find '.$path.' -name "*.java"` > '
	           .$path. '/' . XML_LOG .' 2>&1';
	exec($command);
	
	
	if(file_exists(INFERENCE_LOC) && file_exists(WORLD_XML_LOC)) {
	    chdir(WORLD_XML_LOC);
      	exec('zip -q World.zip World.xml');
      	exec('cp ../scripts/World.zip '. INFERENCE_LOC . ' ' .$path);
      	exec('rm '. WORLD_XML_LOC . ' ../scripts/World.zip ' . INFERENCE_LOC);	
    } else {
        return XML_LOG;
    } 
    return 1;
}

/*
* Helper function that will check the size of the passed $filename at the passed $path location. 
* If the size is 0 it will print out a Success message as a table row and return a 1.  Otherwise 
* it will print the error messages that are contained in the file and return a 0.  The function
* assumes that the $filename passed is the result of the stderr output from a system command. The 
* table row will have a first column data that is obtained from $statusType. 
*/
function checkErrorOutput($path, $filename) {
	$file_path = $path."/".$filename;
	if(filesize($file_path) == 0) {
		return 1;
	} else {
		return $filename;
	}
}



/*
* Deletes all .class files and the output.txt file once confirmation of the files
* validity.  If the files did not compile properly than it will delete the entire
* folder on the server since the uploaded files cannot be used.  If a .zip file 
* was uploaded it will also remove the .zip files once they ahve been successfully
* extracted. 
*/
function cleanup($id, $deleteAll) {
	$path = DIRECTORY."/".$id;
	$deleteString = "";
	if($deleteAll) {
		$deleteString = "-r ".$path;
	} else {
		//$deleteZip = '`find '.$path.' -name "*.zip"`';
		$deleteText = '`find '.$path.' -name "*.txt"` ';
		$deleteClass = '`find '.$path.' -name "*.class"` ';
		$deleteString = $deleteText.$deleteClass;
	}
	exec("rm ".$deleteString);
}
?>