<?php
$file_path = $_REQUEST["path"];
chdir("/homes/abstract/bdwalker/www/uploads/");
if(file_exists('./'.$file_path)){
	$contents = file_get_contents('./'.$file_path);
	print($contents);
}
?>