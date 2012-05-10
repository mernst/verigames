(function( $ ){
	//plugin buttonset vertical
	$.fn.buttonsetv = function() {
	  $(':radio, :checkbox', this).wrap('<div style="margin: 1px"/>');
	  $(this).buttonset();
	 
	  $('label:first', this).removeClass('ui-corner-left').addClass('ui-corner-top');
	  $('label:last', this).removeClass('ui-corner-right').addClass('ui-corner-bottom');
	  
	  var max_width = 0; 
	  
	  $('label', this).each(function(index){
	     var w = $(this).width();
	     if (w > max_width){
	     	 max_width = w; 
	     }
	  })
	  
	  $('label', this).each(function(index){
	    $(this).width(max_width);
	  })
	};
})( jQuery );

function radioClicks(event) {
    var id, filename, file_path, queryString;
    id = event.target.id;
    filename = $("label[for=\'" + id + "\']").text();
    $("#file_name").text(filename);
	queryString = ((location.search.substr(1)).split("?"));
	queryString = queryString[0].split("&");
	file_path = $(this).attr('id');
	id = "path=" + queryString[0].substring(3) +  "/" + file_path;
	$("#text_area").html("Retrieving Contents").load("./scripts/retrieve_file_contents.php", id);
};

function downloadFiles() {
    var id = location.search.substr(1).split("?")[0].split("&")[0].substr(3);
    var zip = $.ajax({
        url:"./scripts/utilities.php",
        type:"POST",
        data:{"function":"zip", "id":id}
    }); 
    
    zip.done(function(response) {
        if(response === "SUCCESS") {
            window.location = "./uploads/"+id+"/results.zip";
        }
    });
}


$(document).ready(
	function() {
	    $('#download_button').bind('click', downloadFiles);
		$('#selectable').selectable({
 			selected: function (event, ui) {
  				alert($(this).find('.ui-selected').attr('id'));
		}})
		var queryString = ((location.search.substr(1)).split("?"));
 		queryString = queryString[0];
 		$("#radio").html(function(){
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
			var target = document.getElementById('message');
			var spinner = new Spinner(opts).spin(target);
			
			var message = document.createElement("div");
			message.id = "message";
			message.innerHTML = "Retrieving Files, Please Wait...";
			$("#radio").append(message);
 		}).load("./scripts/annotate.php",queryString, 
 		         function(response){
 		             $( "#radio" ).buttonsetv();
                     $( "input[name='radio']" ).bind( "click", radioClicks );
                 });	
});
