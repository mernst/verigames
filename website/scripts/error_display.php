<?php
	$file = $_REQUEST["file"];
	$id = $_REQUEST["id"];
	$path =  realpath("../uploads/")."/".$id;	
	$file_path = $path.'/'.$file;
	$handle = fopen($file_path, 'r');
	while($line = fgets($handle)){
		print($line."</br>");
	}
	fclose($handle);

?>