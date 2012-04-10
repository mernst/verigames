$(document).ready(
	function() {
		$('#selectable').selectable({
 			selected: function (event, ui) {
  				alert($(this).find('.ui-selected').attr('id'));
		}})	
});
