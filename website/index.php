<html>
	<head>
		<title>PipeJam</title>
		<link rel=StyleSheet href="./styles/index.css">
		<link rel=StyleSheet href="./uploadify/uploadify.css">
		<script type="text/javascript" src="./scripts/spin.js"></script>
		<script type="text/javascript" src="./scripts/index.js"></script>
		<script type="text/javascript" src="http://www.google.com/jsapi"></script>
  		<script type="text/javascript" src="./jqueryUI/js/jquery-1.7.1.min.js"></script>
		<script type="text/javascript" src="./jqueryUI/js/jquery-ui-1.8.18.custom.min.js"></script>
		<script type="text/javascript" src="./uploadify/swfobject.js"></script>
		<script type="text/javascript" src="./uploadify/jquery.uploadify.v2.1.4.min.js"></script>
	</head>
	<body>
	<div id="container">
		<div id="masthead">
			<div id="logo_holder">
				<img id="logo" src="./resources/PipeJamLogo3.png" width="323" height="89"></img>
			</div>
		</div>
		<div id="button_bar">
			<div id="button_group">
				<span id="play" title="Play A Demo Game" class="buttons">
					Play Demo
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
				<h3>Welcome!</h3>				<p>
					Welcome to PipeJam! The game that allows you to verify your code while you play. 
					You have several options to begin, you can select from our example files 					below or choose to upload your own Java program.  PipeJam will convert your files					into a puzzle game that will annotate your code as you play.  Once you are finished 					solving the puzzle, you will be taken to a results page where you can view the results.
				</p>
				<p>					You can choose to upload .java, .zip or .jar files.  Be sure to include all the files that					are required to compile your program.  If you choose to upload a zip file then it should					contain all the files necessary to run your program.  Once you have uploaded your files and we 					have confirmed they were uploaded and compiled successfully, you will be taken to the 					game.
				</p>
			</div>
			<div id="upload">
				<h3>File Upload</h3>
				<p>
					Choose a type checker to use and then select your own files to upload or select from one of our samples. </br>
				</p>
					<div id="queue">	
						<p>
							Type Checker: 
							<select>
								<option value="null_checker">Null Check</option>
							</select>
						</p>
						<input type="file" name="file[]" id="file_upload"/>
					</div>
					<span id="uploadIt">Upload Files</span>
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