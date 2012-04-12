<html>
	<head>
		<title>PipeJam File Upload</title>
		<link rel=StyleSheet href="./styles/pipejam.css">
		<script type="text/javascript" src="./scripts/spin.js"></script>
		<script type="text/javascript" src="./scripts/index.js"></script>
		<script type="text/javascript" src="http://www.google.com/jsapi"></script>
  		<script type="text/javascript" src="./jqueryUI/js/jquery-1.7.1.min.js"></script>
		<script type="text/javascript" src="./jqueryUI/js/jquery-ui-1.8.18.custom.min.js"></script>
	</head>
	<body>
	<div id="container">
		<div id="masthead">
			<div id="logo_holder">
				<img id="logo" src="./resources/PipeJamLogo2.png" width="250" height="110"></img>
			</div>
		</div>
		<div id="button_bar">
			<div id="button_group">
				<span id="play" class="buttons">
					Play Now
				</span>
				<span id="help" class="buttons">
					Help
				</span>
				<span id="contact" class="buttons">
					Contact Us
				</span>
			</div>
		</div>
		<div id="content">
			<div id="welcome">
			</div>
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
		</div>
		<div id="clear_footer">
		</div>
	</div>
	<div id="footer">
		&copy Department of Computer Science and Engineering, University of Washington, Seattle
	</div>
	</body>
</html>