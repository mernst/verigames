//keeps track of the number of files to be uploaded
var count = 1;
var uploadGUID = -1;
var PHP_SCRIPT= "./scripts/pipejam.php"; //this should be treated as a constant
var UPLOADIFY_LOC = "./uploadify/uploadify.swf"; //this should be treated as a constant
/*
* Function to attach observers to the "remove" button that will appear in 
* the file upload box.  It will cause the button to be underlines when the
* mouse rolls over the button and will remove the underline upon the mouse 
* moving out of the button. 
*/
function attachMouseoverObserver(id) {
	id = "#" + id;
	$(id).bind('mouseover', function(event){
		$(id).css("textDecoration", "underline");
	});
	
	$(id).bind('mouseout', function(event){
		$(id).css("textDecoration","none");
	});
}

/*
* Function that will remove any observers connected to a div that is going 
* to be removed.  This will be called when the user clicks the "remove" option
* from the file upload box.  The function will remove the observer attached 
* to the div and then remove it from the page. 
*/
function attachRemoveDivObserver(id) {
	//listen for mouseclick
	id = "#" + id;
	$(id).bind('click', function(event) {
		$(this).parent().remove();
	});
}


/*
* Function that will attach both the mouse over listeners to the "remove" button
* in the file upload box and the remove div listeners that will remove the div
* from the view should the user click the "remove" button. 
*/ 
function attachObservers(id){
	attachRemoveDivObserver(id)
	attachMouseoverObserver(id);
}

function checkForValidFiles(inputFiles) {
	if(inputFiles.length == 0) {
		return 0;
	}
	
	for(var i = 0; i < inputFiles.length; i++) {
		element = inputFiles[i];
		if($(element).val() == "") {
			return 0;
		} 
	}
	return 1;
}

function showSpinner(targetId){
	var opts = {
  		lines: 12, // The number of lines to draw
 		length: 7, // The length of each line
  		width: 2, // The line thickness
  		radius: 5, // The radius of the inner circle
  		color: '#ffffff', // #rgb or #rrggbb
  		speed: 3, // Rounds per second
  		trail: 60, // Afterglow percentage
  		shadow: false, // Whether to render a shadow
  		hwaccel: false, // Whether to use hardware acceleration
  		top:'0px',
  		left:'100px'
	};
	var target = document.getElementById(targetId);
	var spinner = new Spinner(opts).spin(target);
}


function uploadFiles(event) {
    if($('#file_upload').uploadifySettings('queueSize') > 0) {
      	$(this).modal();
      	showSpinner('upload-spin');
      	var upload = $.ajax({
      		url: "./scripts/guid.php"
      	})
      	
      	upload.done(function(guid) {
      		uploadGUID = guid;
      		$('#file_upload').uploadifySettings('folder', "/"+guid);
      		$('#file_upload').uploadifyUpload();
      	});
     }
}	

function checkUpload(event, ID, fileObj, response, data) {
	if(response !== "SUCCESS") {
		$('#file_upload').uploadifyClearQueue();
	} else {
	   //print error
	}
}



function compileFiles() {
	showSpinner("compile-spin");
	var request = $.ajax({
		url: PHP_SCRIPT,
		type: "POST",
		data: {"function":"compile", "guid":uploadGUID}
	});
	request.done(function(response) {
		if(response === "SUCCESS") {
			$('#compile-spin').html("<img style='opacity:1.0' width='25' height='25' src='./resources/success.png'/>");
			createXML();
		} else {
			$('#compile-spin').html("<a style='color:red' target='_blank' href='scripts/error_display.php?file=compile_output.txt&id="
			 + uploadGUID + "\'>Error</a>");
				
		}
	});
}

function unzipFiles(event) {
	$('#upload-spin').html("<img style='opacity:1.0' width='25' height='25' src='./resources/success.png'/>");
	showSpinner("unzip-spin");
	var request = $.ajax({
		url: PHP_SCRIPT,
		type:"POST",
		data:{"function":"unzip", "guid": uploadGUID}
	});
	
	request.done(function(response) {
		if(response === "SUCCESS") {
			$('#unzip-spin').html("<img style='opacity:1.0' width='25' height='25' src='./resources/success.png'/>");
			compileFiles();
		}
	});	
}

function createXML() {
	showSpinner("verify-spin");
	var typeChecker = $('option:selected').val();
	var request = $.ajax({
		url: PHP_SCRIPT,
	 	type: "POST",
		data: {"function":"xml", "guid":uploadGUID, "script":typeChecker}
	});
	request.done(function(response) {
		if(response === "SUCCESS") {
			$('#verify-spin').html("<img width='25' height='25' src='./resources/success.png'/>");
			cleanup();
		}else{
			$('#verify-spin').html("<a style='color:red' target='_blank' href='scripts/error_display.php?file="+response+"&id="
			 + uploadGUID + "\'>Error</a>"); 
		}
	});
}

function cleanup(all) {
    //if not passed, default to false
    all = typeof all !== 'undefined' ? all : false;
    
    //if true is passed then the entire directory should be removed
    var toCall = (all)?"cleanup_all":"cleanup";
	$.ajax({
		url:PHP_SCRIPT,
		type: "POST",
		data: {"function":toCall, "guid": uploadGUID}
	}).done(function(response) {
	   if(response !== "all_removed") 
	       playGame();
	});
}

function playGame(){
    var typeChecker = $('option:selected').val();
	window.location = "webgame.php?id=" + uploadGUID + "&checker=" + typeChecker;
}

function showOptions(event) {
	position = $(this).offset();
	labelPosition = $('#typechecker').position();
	labelWidth = $('#typechecker').outerWidth();
	buttonWidth = $('#select_typechecker').outerWidth();
	totalWidth = labelWidth + buttonWidth;
	totalHeight = $('#typechecker').height();
	$('#type_options').position({
		top:	labelPosition.top + totalHeight,
		left:	labelPosition.left
	});
}


window.onload = function() {
	attachMouseoverObserver("button");
	attachMouseoverObserver("test_button");
	$('#uploadIt').bind('click', uploadFiles);
	$('#select_typechecker').bind('click', showOptions);
  	$('#file_upload').uploadify({
  	  'uploader'  : UPLOADIFY_LOC,
  	  'script'    : PHP_SCRIPT,
  	  'removeCompleted' : false,
  	  'cancelImg' : './uploadify/cancelred.png',
  	  'multi'	  : true,
  	  'fileExt'   : '*.zip;*.java;*.jar',
  	  'fileDesc' : 'Java Source Files',
  	  'sizeLimit' : 10485760,
  	  'width'	  : 134,
  	  'auto'      : false,
  	  'queueID'   : 'queue',
  	  'queueSizeLimit' : 10,
  	  'simUploadLimit' : 10,
  	  'onComplete' : checkUpload,
  	  'onAllComplete' : unzipFiles
 	 });
}