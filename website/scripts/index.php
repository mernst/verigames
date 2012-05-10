<html>
	<head>
		<title>PipeJam File Upload</title>
		<link rel=StyleSheet href="./styles/pipejam.css">
		<script type="text/javascript" src="./scripts/spin.js"></script>
		<script type="text/javascript" src="./scripts/index.js"></script>
		<script type="text/javascript" src="http://www.google.com/jsapi"></script>
  		<!--<script type="text/javascript">google.load("prototype", "1.6.0.2");</script>-->
  		<script type="text/javascript" src="./jqueryUI/js/jquery-1.7.1.min.js"></script>
		<script type="text/javascript" src="./jqueryUI/js/jquery-ui-1.8.18.custom.min.js"></script>
	</head>
	<body>
	<div id="upload">
		<form action="./scripts/pipejam.php" id="file_form" method="post" enctype="multipart/form-data">
			<fieldset id="resources">
			<legend> Choose .java, .jar or .zip file(s) to upload: </legend>
				<div id="buttons">			
				</div>
			<a id="button" class="common_style" href="#">Add files</a></br>
			</fieldset>
			<div id="samples">You can play a sample game 
				<a href="./flash_files/webgame.html?sample=sample1.xml">here</a>
			</div>
			<input id='submit_button' type="submit" name="submit_button" value="Upload File(s)"/>
		</form>
		<div id='progress'><div id='spinner'></div></div>
		<div id="message">
		</div>
	</div>
	</body>
</html>