//keeps track of the number of files to be uploaded
var count = 1;


/*
* Function to attach observers to the "remove" button that will appear in 
* the file upload box.  It will cause the button to be underlines when the
* mouse rolls over the button and will remove the underline upon the mouse 
* moving out of the button. 
*/
function attachMouseoverObserver(id){
	Event.observe(id,'mouseover', function(event){
		$(id).setStyle({
			textDecoration:'underline'
		});
	});
	
	Event.observe(id, 'mouseout', function(event){
		$(id).setStyle({
			textDecoration:'none'
		});
	});
}

/*
* Function that will remove any observers connected to a div that is going 
* to be removed.  This will be called when the user clicks the "remove" option
* from the file upload box.  The function will remove the observer attached 
* to the div and then remove it from the page. 
*/
function attachRemoveDivObserver(id){
	//listen for mouseclick
	Event.observe(id, 'click', function(event){
		$(id).stopObserving('mouseover');
		$(id).stopObserving('mouseout');
		this.parentNode.remove();
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

function showProgress(event){
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
	
	var message = document.createElement("div");
	message.id = "message";
	message.innerHTML = "Uploading Files, Please Wait";
	$("upload").appendChild(message);
}


/*
* function to add a new file upload button. This is called as the result of the
* user selecting to "Add additional files" from the upload selection box.  
*/
function addButton(event){
	//create new <div> with browse button and remove button
	var newButton, div, remove, newId;
	newButton = document.createElement("input");
	div = document.createElement("div");
	remove = document.createElement("a");
	newId = "button"+count;
	count+=1;

	//setup new button
	newButton.type = 'file';
	newButton.name = 'file[]';
	
	//Setup remove button
	remove.href = "#";
	remove.innerHTML = "remove";
	
	remove.id = newId;
	remove.addClassName('common_style');
	
	
	//insert into html
	div.appendChild(newButton);
	div.appendChild(remove);
	$('buttons').appendChild(div);
	
	attachObservers(newId);

}

window.onload = function(){
	attachMouseoverObserver("button");
	Event.observe('submit', 'click', showProgress);
	Event.observe('button', 'click', addButton);
}