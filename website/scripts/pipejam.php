<?php
/*
* 
*/
define("DIRECTORY", realpath("../uploads/")."/");
define("MAX_SIZE", 10485760);
?>
<html>
<head>
	<title>Upload Results</title>
	<link rel=StyleSheet href="../styles/upload.css">
</head>
<body>
<?php
if(count($_FILES['file']) == 0){?>
	<div id="results">
		No Files Uploaded.
		<a href="../index.php">Back</a>
	</div><?php
}else{
?> 

	<div id="results">
		<table border="1px">
			<th>Status</th>
			<th>Results</th>
			<?php
				$uniqueID = uniqid();
				if(moveFiles($uniqueID)){
					unzipFiles($uniqueID);
				}
				$success = checkFileValidity($uniqueID);
				$xmlCreation = 0;
				if($success){
					$xmlCreation = createXMLFile($uniqueID);
				}
				cleanup($uniqueID, !$success);
			?>
		</table>
		<div id="buttons">
			<a href="../index.php">Back</a><?php
				if($xmlCreation){
					?><span id="play">
						<a  href="../flash_files/webgame.html?id=<?php echo rawurlencode($uniqueID)?>">Play Game</a>
					  </span><?php
				}?>
		</div>
	</div>
	
</body>
</html>
<?php
}

/*
* Function that determines the validity of the user uploaded files and will move them to 
* a unique folder for each user.  The function take a $id parameter that is a unique guid. 
* It will determine if the files uploaded are either a .java or .zip file, that they don't
* exceed the maximum size (determined by the MAX_SIZE constant), and that the upload process
* was successful. If all tests pass it will copy the files over to the users folder and 
* display and errors in the process. It will display the status of the upload as an html
* table row.  It will return a boolean of true if the file was a .zip file and required
* unzipping, false otherwise. 
*/
function moveFiles($id){
	$requireUnzip = False;
	print "<tr><td>Upload Status</td><td>";
	foreach($_FILES["file"]["error"] as $key => $error){
		$name = $_FILES["file"]["name"][$key];
		$pieces = explode(".", $name);
		$fileExtension = $pieces[count($pieces) - 1];
		
		//check to see if files need to be unzipped
		if(strcmp($fileExtension, "zip") == 0){
			$requireUnzip = True;
		}
		
		if(($requireUnzip || strcmp($fileExtension, "java") == 0) && count($pieces) <= 2){
				//valid files, move to folder				
				$tempName = $_FILES["file"]["tmp_name"][$key];
				$path = DIRECTORY.$id."/";
				
				//create folder if it doesn't exist
				if(!file_exists($path)){
					mkdir($path);
				}

				//Display upload status
				if(move_uploaded_file($tempName, $path.$name)){
					print($name." uploaded successfully</br>");
				}else{
					print("File ".$name." failed to upload</br>");
				}
		}else{
			//display error
			$size = $_FILES["file"]["size"][$key];
			$error = $_FILES["file"]["error"][$key];
			print "<tr><td>Upload Status</td>";
			if($error == UPLOAD_ERR_OK && $size < MAX_SIZE){
				print("Invalid file format uploaded (\"".$name."\"). Must be a .java or .zip file");
			}else{
				if($size > 1){
					$size /= 1024;
					print("File ".$name." was too large (".$size." Kb) must be below ".MAX_SIZE);
				}else{
					print("There was an upload error.  File ".$name." failed to upload with error: </br> ".$error);
				}
			}		
		}	
	}
	print "</td></tr>";
	return $requireUnzip;
}

/*
* Function that will unzip the .zip file the user uploaded. Function will call the unix
* unzip utility and output all the files to the users unique folder determined by the 
* $id parameter passed.  The $id parameter should be a unique guid.  The function will
* print the status of the unzipping ot the user in the format of an html table row. 
*/
function unzipFiles($id){
	$path = DIRECTORY.$id."/";
	$handle = popen('unzip -o `find '.$path.' -name "*.zip"` -d '.$path, 'r');
	
	//display unzip status
	print "<tr><td>Unzip Status</td>";
	print "<td>";
	while(($result = fgets($handle, 1024)) != false){
		print $result."</br>";
	}
	print "</td></tr>";
	
	pclose($handle);	
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
	$path = DIRECTORY.$id;

	system('javac -Xlint:none -classpath .:../java/verigames.jar `find '.$path.' -name "*.java"` 2> '.$path.'/output.txt');
	
	
	//display compile status
	return printErrorOutput($path, "output.txt", "Compile Status");
}

/*
* Function creates the xml file that will be used with the flash game files.  It depends on the
* verigames.sh script file.  It will copy over the World.xml and the inference.jaif file created
* by the verigames.sh file.  It will return a 1 if the file was created successfully, otherwise
* it will return a 0. 
*/
function createXMLFile($id){
	$path = DIRECTORY.$id;
	
	//This needs to be changed, need to redirect file output
	exec('sh ../scripts/verigames.sh `find '.$path.' -name "*.java"` 1> '.$path.'/script.txt 2> '.$path.'/error.txt');
	exec('cp ../scripts/World.xml ../scripts/inference.jaif '.$path);
	exec('rm ../scripts/World.xml ../scripts/inference.jaif ');	
	
	return printErrorOutput($path, "error.txt", "XMLCreation");
}

/*
* Helper function that will check the size of the passed $filename at the passed $path location. 
* If the size is 0 it will print out a Success message as a table row and return a 1.  Otherwise 
* it will print the error messages that are contained in the file and return a 0.  The function
* assumes that the $filename passed is the result of the stderr output from a system command. The 
* table row will have a first column data that is obtained from $statusType. 
*/
function printErrorOutput($path, $filename, $statusType){
	print "<tr><td>".$statusType."</td>";
	if(filesize($path.'/'.$filename) == 0){
		print("<td>Success! </td>");
		return 1;
	}else{
		print("<td>");
		$file = $path.'/'.$filename;
		$handle = fopen($file, 'r');
		while($line = fgets($handle)){
			print($line."</br>");
		}
		fclose($handle);
		return 0;
	}
	print "</td></tr>";
}



/*
* Deletes all .class files and the output.txt file once confirmation of the files
* validity.  If the files did not compile properly than it will delete the entire
* folder on the server since the uploaded files cannot be used.  If a .zip file 
* was uploaded it will also remove the .zip files once they ahve been successfully
* extracted. 
*/
function cleanup($id, $deleteAll){
	$path = DIRECTORY.$id;
	$deleteString = "";
	if($deleteAll){
		$deleteString = "-r ".$path;
	}else{
		$deleteZip = '`find '.$path.' -name "*.zip"`';
		$deleteOutput = $path."/output.txt ";
		$deleteError = $path."/error.txt ";
		//$deleteClass = '`find '.$path.' -name "*.class"` ';
		$deleteString = $deleteOutput.$deleteError.$deleteZip;
	}
	system("rm ".$deleteString);
}
?>