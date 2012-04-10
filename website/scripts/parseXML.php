<?php

$folder = $_REQUEST["folder"];
$xml = $_REQUEST["xml"];
if($folder && $xml){
	$file = '../uploads/'.$folder.'/updatedXML.xml';
	/*system('touch '.$file);
	$handle = fopen($file, 'w');
	fwrite($handle, $xml, strlen($xml)*16);
	fclose($handle);*/
	file_put_contents($file, $xml);
	
}else{
	print($error);
}

?>