<?php
    include("./scripts/common_include.php");
	include("./scripts/globals.php");
?>
			<title>PipeJam</title>
			<link rel=StyleSheet href="./styles/index.css">
			<link rel=StyleSheet href="./uploadify/uploadify.css">
			<script type="text/javascript" src="./uploadify/jquery.uploadify-3.1.min.js"></script>
			<script type="text/javascript" src="./scripts/upload.js"></script>
			<script type="text/javascript" src="./scripts/compile.js"></script>
			<script type="text/javascript" src="./scripts/createXML.js"></script>
			<script type="text/javascript" src="./scripts/main.js"></script>
<?php
	include("./scripts/header.php");
?>
		<div id="content">
			<div id="welcome">
				<h3>Welcome!</h3>
				<p>
					Welcome to PipeJam! The game that allows you to verify your code while you play. 
				 	PipeJam will convert your files into a puzzle game that will annotate your code
				 	as you play.  Once finished, you can view and download your annotated code.
				</p>
				<p>
					You can choose to upload .java, .zip or .jar files.  Be sure to include all the files that
					are required to compile your program. 
				</p>
			</div>
			<div id="upload">
				<h3>File Upload</h3>
				<p>
					Choose a type checker and theme then select your files to upload. <br/>
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
				</div>
			</div>
		</div>
		<div id="clear_footer">
		</div>
	</div><?php
	include("./scripts/footer.php");
?>
