<?php

$folder = $_REQUEST["folder"];
$xml = $_REQUEST["xml"];
if($folder && $xml){
	$file = '../uploads/'.$folder.'/updatedXML.xml';
	file_put_contents($file, $xml);
	
}else{
	print($error);
}

?>