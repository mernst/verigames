//keeps track of the number of files to be uploaded
var count = 1;


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


function showProgress(event) {
	event.preventDefault();
	var result = checkForValidFiles($(':file'));
	$("#message").html('');
	if(result == 1) {
		var opts = {
	  		lines: 12, // The number of lines to draw
	 		length: 7, // The length of each line
	  		width: 2, // The line thickness
	  		radius: 6, // The radius of the inner circle
	  		color: '#2659E5', // #rgb or #rrggbb
	  		speed: 2, // Rounds per second
	  		trail: 60, // Afterglow percentage
	  		shadow: false, // Whether to render a shadow
	  		hwaccel: false // Whether to use hardware acceleration
		};
		var target = document.getElementById('spinner');
		var spinner = new Spinner(opts).spin(target);
		
		
		message = "Uploading Files, Please Wait";
		$("#message").append(message);
		document.getElementById("file_form").submit();
	}else {
		message = "Please select a file";
		$("#message").append(message);
	}
}


/*
* function to add a new file upload button. This is called as the result of the
* user selecting to "Add additional files" from the upload selection box.  
*/
function addButton(event) {

	//create new <div> with browse button and remove button
	var newButton, div, remove, newId;
	

	newId = "button"+count;
	count+=1;
	
	$('#buttons').append($("<div>"+
							"<input type='file' name='file[]'/><a href='#' id="+ newId + " class='common_style'>Remove</a>" + 
						   "</div>"));
		
	attachObservers(newId);

}

window.onload = function() {
	attachMouseoverObserver("button");
	$('#submit_button').bind('click', showProgress);
	$('#button').bind('click', addButton);
}