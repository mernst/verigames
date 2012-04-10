<?php
 
$id = $_GET["id"];	
$path = $id;
chdir('../uploads/'.$id);
$javaPath = '/homes/abstract/bdwalker/www/java/';
$scriptPath = '/homes/abstract/bdwalker/www/scripts/';
exec("cp ".$scriptPath."world.dtd /homes/abstract/bdwalker/www/uploads/".$id."/world.dtd 2> fail.txt");
exec("export CLASSPATH=".$javaPath);
exec('java -cp '.$javaPath.'/verigames.jar JAIFParser ./updatedXML.xml ./inference.jaif ./updatedInference.jaif 2> scriptError.txt');	
if(file_exists("./updatedInference.jaif") &&  !file_exists("./inference-output")){
	$output = './inference-output';
	$input = './updatedInference.jaif';
	exec('java -cp '.$javaPath.'verigames.jar annotator.Main -d '.$output.' '.$input.' `find -name "*.java"` 2> annotateError.txt');	
}
displayFiles($path, $id);


function displayFiles($path, $id){
	$files = shell_exec("find ./inference-output/*.java ./inference-output/*/*.java");
	$files = explode("\n", $files);
	$full_path=('/uploads/'.$id.'/inference-output/');
	
	foreach($files as $file){
		$file_array = explode("/", $file);
		$last = count($file_array) - 1;
		print("<input type=\"radio\" id=".$file." name=\"radio\"/><label for=".$file.">".$file_array[$last]."</label>");
	}
}
?>