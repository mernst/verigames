//keeps track of the number of files to be uploaded
var count = 1;
var uploadGUID = -1;
var PHP_SCRIPT = "./scripts/pipejam.php"; //this should be treated as a constant
var UPLOADIFY_LOC = "./uploadify/uploadify.swf"; //this should be treated as a constant


/*
* Function that will remove any observers connected to a div that is going 
* to be removed.  This will be called when the user clicks the "remove" option
* from the file upload box.  The function will remove the observer attached 
* to the div and then remove it from the page. 
*/
function attachRemoveDivObserver(id) {
    //listen for mouseclick
    id = "#" + id;
    $(id).bind('click', function (event) {
        $(this).parent().remove();
    });
}


/*
* Function is called when the user's files have been uploaded, compiled and verified. 
* The function will redirect the webpage to the game and send the user selected typechecker
* as a query parameter. 
*/
function playGame() {
    var typeChecker = $('option:selected').val();
    window.location = "webgame.php?id=" + uploadGUID + "&checker=" + typeChecker;
}

/*
* Function called as the last stage of the user upload process. It will remove all the 
* unnecessary files that were a part of the verification process. For instance, the .class files
* created during the compilation process are no longer needed and will be removed.  Once the cleanup
* is complete this function will call playGame() that will redirect the user to the game. There 
* is an optional argument.  If passed True, it will remove all of the user's files.  If not passed
* or False is passed it will only remove the unncessary files. 
*/
function cleanup(all) {
    var toCall, cleanup;

    //if not passed, default to false
    all = typeof all !== 'undefined' ? all : false;

    //if true is passed then the entire directory should be removed
    toCall = (all) ? "cleanup_all" : "cleanup";
	cleanup = $.ajax({
        url     : PHP_SCRIPT,
        type    : "POST",
        data    : {"function" : toCall, "guid" : uploadGUID}
    })

    cleanup.done(function (response) {
        if (!all) {
            playGame();
        }
    });
}

/*
* Function that will display the progress spinner in the DOM object indicated by the passed
* id.  The id should represent a block element on the webpage.  It will embed the spinner
* as a child element in the DOM object.
*/
function showSpinner(targetId) {
    var opts, target, spinner;
    opts = {
        lines   : 12, // The number of lines to draw
        length  : 7, // The length of each line
        width   : 2, // The line thickness
        radius  : 5, // The radius of the inner circle
        color   : '#ffffff', // #rgb or #rrggbb
        speed   : 3, // Rounds per second
        trail   : 60, // Afterglow percentage
        shadow  : false, // Whether to render a shadow
        hwaccel : false, // Whether to use hardware acceleration
        top     : '0px',
        left    : '100px'
    };
    target = document.getElementById(targetId);
    spinner = new Spinner(opts).spin(target);
}


/*
* Function that creates the necessary XML for use with the game.  It will make an Ajax request
* to the server with the user's unique guid file.  It will then wait for a response from the
* server before continuing to the next step fo the user upload process.  If the response from
* the server indicates the successful creation of the XML the function will call the cleanup
* function. */
function createXML() {
    var typeChecker, request;
    showSpinner("verify-spin");
    typeChecker = $('option:selected').val();

    //make ajax request to create XML file
    request = $.ajax({
        url     : PHP_SCRIPT,
        type    : "POST",
        data    : {"function" : "xml", "guid" : uploadGUID, "script" : typeChecker}
    });

	//wait for ajax request to complete before continuing
    request.done(function (response) {
        if (response === "SUCCESS") {
            $('#verify-spin').html("<img width='25' height='25' src='./resources/success.png'/>");
            cleanup();
        } else {
            $('#verify-spin').html("<a style='color:red' target='_blank' " +
                "href='scripts/utilities.php" +
                "?function=displayError&file=" + response + "&id=" + uploadGUID + "\'>Error</a>");
        }
    });
}

/*
* Function that will attempt to compile the files uploaded by the user.  It will make an
* Ajax call to the server and wait for the response before continuing.  If the server indicates
* that all files were successfully compiled, it will call the createXML() function to continue
* the user upload process. If there was a failure compiling, the function will display a link
* to the file containing the compiling error. 
*/
function compileFiles() {
    showSpinner("compile-spin");
    var request = $.ajax({
        url   : PHP_SCRIPT,
        type  : "POST",
        data  : {"function" : "compile", "guid" : uploadGUID}
    });

    //wait for Ajax request to complete.  If successful, continue, otherwise display an error
    request.done(function (response) {
        if (response === "SUCCESS") {
            $('#compile-spin').html("<img style='opacity:1.0' width='25' height='25'" +
                " src='./resources/success.png'/>");
            createXML();
        } else {
            $('#compile-spin').html("<a style='color:red' target='_blank' " +
                " href='scripts/utilities.php" +
                "?function=displayError&file=compile_output.txt&id=" + uploadGUID + "\'>Error</a>");
        }
    });
}

/*
* Function that will upload the selected user files to the server.  It will call the uploadify
* object and ask it to upload all files in its queue.  Once uploadify has indicated that it has
* completed it will start the file verification process. If there was an error uploading the files
* an error will be displayed. 
*/
function uploadFiles() {
    if ($('#queue').find('.fileName').length !== 0) {
        $(this).modal();
        showSpinner('upload-spin');

        //upload files via uploadify object
        if (uploadGUID !== -1) {
            $('#file_upload').uploadify('upload', '*');
        }
    }
}




/*
* Function that will make an Ajax call to unzip the files uploaded by the user.  The function
* does not make any attempt to verify whether the user uploaded .zip files.  It will simply 
* attempt to unzip them and if no .zip file was uploaded then there will be no changed made 
* to the uploaded files. If the unzipping process was successful or if no zip files were 
* uploaded, it will call the compileFiles() method to validate the uploaded files. 
*/
function unzipFiles(event) {
    $('#upload-spin').html("<img style='opacity:1.0' width='25' height='25' " +
        "src='./resources/success.png'/>");
    showSpinner("unzip-spin");

    //make an Ajax request to unzip any uploaded zip files
    var request = $.ajax({
        url     : PHP_SCRIPT,
        type    : "POST",
        data    : {"function" : "unzip", "guid" : uploadGUID}
    });

    //wait for Ajax request to complete, if successful move on to the next stage
    request.done(function (response) {
        if (response === "SUCCESS") {
            $('#unzip-spin').html("<img style='opacity:1.0' width='25' height='25' " +
                "src='./resources/success.png'/>");
            compileFiles();
        }
    });
}


window.onload = function () {
    //obtain the unique guid for this user
    var upload = $.ajax({
        url: "./scripts/utilities.php",
        type: "POST",
        data: {'function': 'getGUID'}
    });

    //bind buttons to jQuery action listeners
    $('#uploadIt').bind('click', uploadFiles);

    //once the guid has been received, setup the uploadify object 
    upload.done(function (guid) {
        uploadGUID = guid;
        $('#file_upload').uploadify({
            'swf'            : UPLOADIFY_LOC,
            'uploader'       : './scripts/pipejam.php?folder=' + guid,
            'removeCompleted': false,
            'multi'          : true,
            'fileTypeExts'   : '*.zip;*.java;*.jar',
            'fileTypeDesc'   : 'Java Source Files',
            'fileSizeLimit'  : '10MB',
            'width'          : 134,
            'auto'           : false,
            'queueID'        : 'queue',
            'queueSizeLimit' : 10,
            'onQueueComplete': unzipFiles,
            'requeueErrors'  : false
        });
    });
}
