<?php
if(strpos($_GET['function'], '2') != false)
{
	if(strpos($_GET['function'], 'POST') != false)
	 {
		//handle all POST requests here, as we need to pass a third argument (at least) the posted data or file info
		if(strpos($_GET['function'], 'Robot') != false)
		{
			//args are function, userID, fileName, fileData
			exec("python dbInterface2.py " . $_GET['function'] . " " . $_GET['data_id'] . " '" . $_FILES["file"]["name"] . "' '" . $_FILES["file"]["tmp_name"] . "'", $output);
			echo $output[0];
		}
		else
		{
			//all functions that submit a file for saving contain 'POST' in the name
			#echo $_GET['data_id'];
			exec("python dbInterface2.py " . $_GET['function'] . " " . $_GET['data_id'] . " '" . $HTTP_RAW_POST_DATA . "'", $output);
			echo $output[0];
		}
	}
	else
	{
		exec("python dbInterface2.py " . $_GET['function'] . " " . $_GET['data_id'], $output);

		echo $output[0];
	}
}
else if(strpos($_GET['function'], 'Robot') != false)
{
	if(strpos($_GET['function'], 'POST') != false)
	 {
		//handle all POST requests here, as we need to pass a third argument (at least) the posted data or file info
		if(strpos($_GET['function'], 'Robot') != false)
		{
			//args are function, userID, fileName, fileData
			exec("python dbInterfaceRobot.py " . $_GET['function'] . " " . $_GET['data_id'] . " '" . $_FILES["file"]["name"] . "' '" . $_FILES["file"]["tmp_name"] . "'", $output);
			echo $output[0];
		}
		else
		{
			//all functions that submit a file for saving contain 'POST' in the name
			#echo $_GET['data_id'];
			exec("python dbInterfaceRobot.py " . $_GET['function'] . " " . $_GET['data_id'] . " '" . $HTTP_RAW_POST_DATA . "'", $output);
			echo $output[0];
		}
	}
	else
	{
		exec("python dbInterfaceRobot.py " . $_GET['function'] . " " . $_GET['data_id'], $output);

		//the first is for the soon to be defunct group support
		if(strpos($_GET['function'],'getFile') === false)
			echo $_GET['jsonp_callback'] . '(' . $output[0] . ')';
		else
			echo $output[0];
	}
}
else

{
	if(strpos($_GET['function'], 'POST') != false)
	 {
		//handle all POST requests here, as we need to pass a third argument (at least) the posted data or file info
		if(strpos($_GET['function'], 'Robot') != false)
		{
			//args are function, userID, fileName, fileData
			exec("python dbInterface.py " . $_GET['function'] . " " . $_GET['data_id'] . " '" . $_FILES["file"]["name"] . "' '" . $_FILES["file"]["tmp_name"] . "'", $output);
			echo $output[0];
		}
		else
		{
			//all functions that submit a file for saving contain 'POST' in the name
			#echo $_GET['data_id'];
			exec("python dbInterface.py " . $_GET['function'] . " " . $_GET['data_id'] . " '" . $HTTP_RAW_POST_DATA . "'", $output);
			echo $output[0];
		}
	}
	else
	{
		exec("python dbInterface.py " . $_GET['function'] . " " . $_GET['data_id'], $output);

		//the first is for the soon to be defunct group support
		if(strpos($_GET['function'],'getFile') === false)
			echo $_GET['jsonp_callback'] . '(' . $output[0] . ')';
		else
			echo $output[0];
	}
}
?>
