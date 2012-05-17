<?php
    include("./scripts/common_include.php");
?>
			<title>PipeJam</title>
			<link rel=StyleSheet href="./uploadify/uploadify.css">
			<script type="text/javascript" src="./uploadify/swfobject.js"></script>
			<script type="text/javascript" src="./uploadify/jquery.uploadify.v2.1.4.min.js"></script>
			<script type="text/javascript" src="./scripts/index.js"></script>
<?php
	include("./scripts/header.php");
?>
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
					Choose a type checker to use and then select your own files to upload or select from one of our samples. <br/>
				</p>
					
				<div id="upload_options"> 
					<div id="input_box" style="float:left;">
						<input  type="file" name="file[]" id="file_upload"/>
					</div>
					<div id='options'>
						Type Checker:
						<select id='typechecker_options'>
							<option value="infer-nninf.sh">Nullness Checker</option>
							<option value="infer-trusted.sh">Trusted Checker</option>
						</select>
					</div>
					
				</div>
				<div id="queue">	
				</div>
				<span id="uploadIt">Upload Files</span>
				<div id='progress'><div id='spinner'></div></div>
				<div id="message">
				</div>
			</div>
		</div>
		<div id="clear_footer">
		</div>
	</div><?php
	include("./scripts/footer.php");
?>
