<?php
	exec("python dbInterface.py " . $_GET['function'] . " " . $_GET['data_id'], $output);
	echo $_GET['jsonp_callback'] . '(' . $output[0] . ')';
?>
