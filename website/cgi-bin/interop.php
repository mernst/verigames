<?php

	
	//all functions that submit a file for saving contain 'saveFile' in the name
	if(strpos($_GET['function'], 'POST') !== false)
 	{
		#echo $_GET['data_id'];
		exec("python dbInterface.py " . $_GET['function'] . " " . $_GET['data_id']. " '" . $HTTP_RAW_POST_DATA . "'", $output);
		echo $output[0];
	}
	else
	{
		exec("python dbInterface.py " . $_GET['function'] . " " . $_GET['data_id'], $output);

		if(strpos($_GET['function'],'getFile') !== false)
			echo $output[0];
		else
			echo $_GET['jsonp_callback'] . '(' . $output[0] . ')';
	}
?>
