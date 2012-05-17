<?php
  //  include("./scripts/common_include.php");
?>
    <!-- 
    Smart developers always View Source. 
    
    This application was built using Adobe Flex, an open source framework
    for building rich Internet applications that get delivered via the
    Flash Player or to desktops via Adobe AIR. 
    
    Learn more about Flex at http://flex.org 
    // -->
<html>
    <head>
        <title></title>
        <link rel=StyleSheet href="./styles/game.css">       
        <script type="text/javascript" src="http://www.google.com/jsapi"></script>
        <script type="text/javascript">google.load("prototype", "1.6.0.2");</script>
        <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
		<!-- Include CSS to eliminate any default margins/padding and set the height of the html element and 
		     the body element to 100%, because Firefox, or any Gecko based browser, interprets percentage as 
			 the percentage of the height of its parent container, which has to be set explicitly.  Fix for
			 Firefox 3.6 focus border issues.  Initially, don't display flashContent div so it won't show 
			 if JavaScript disabled.
		-->
        <style type="text/css" media="screen"> 
			html, body	{ height:768px; }
			body { margin:0; padding:0; overflow:auto; background-color: #ffffff; }   
			object:focus { outline:none; }
			#flashContent { display:none; border-style:solid; border-width:4px;
			       border-color:#313131; }
        </style>
		    
        <script type="text/javascript" src="./flash_files/js/swfobject.js"></script>
        <script type="text/javascript">
        	var queryString, parameters, paramMap;
            queryString = ((location.search.substr(1)).split("?"));
            parameters = queryString[0].split("&");
            paramMap = parseParameters(parameters);
        	
        	var xmlLoc, uniqueFolder, checker;
        	checker = paramMap["checker"];
        	if(paramMap["sample"]){
        		xmlLoc = "./samples/" + paramMap["sample"];
        	}else if(paramMap["id"]){
        		xmlLoc = "./uploads/" + paramMap["id"] + "/World.zip";
        		uniqueFolder = paramMap["id"];
        	}
			var debug = paramMap["debug"]?paramMap["debug"]:false;
        	
            <!-- For version detection, set to min. required Flash Player version, or 0 (or 0.0.0), for no version detection. --> 
            var swfVersionStr = "10.0.0";
            <!-- To use express install, set to expressInstall.swf, otherwise the empty string. -->
            var xiSwfUrlStr = "expressInstall.swf";
            var flashvars = {debug_mode:debug,world_zip_url:encodeURIComponent(xmlLoc)};
            var params = {};
            params.quality = "high";
            params.bgcolor = "#ffffff";
            params.allowscriptaccess = "sameDomain";
            params.allowfullscreen = "true";
            var attributes = {};
            attributes.id = "Game";
            attributes.name = "Game";
            attributes.align = "middle";
            attributes.margin= "30px";
            swfobject.embedSWF(
                "./flash_files/WebGame.swf?version=6g", "flashContent", 
                "100%", "100%", 
                swfVersionStr, xiSwfUrlStr, 
                flashvars, params, attributes);
			<!-- JavaScript enabled so display the flashContent div in case it is not replaced with a swf object. -->
			swfobject.createCSS("#flashContent", "display:block;text-align:center;");
			
			function printDebug(message) {
				document.getElementById("debug").value = message + "\n : " + document.getElementById("debug").value;
			}
			
			function receiveUpdatedXML(updated_xml, quit) {
				// Process XML here:
				if(uniqueFolder){
					saveXML(updated_xml, quit);
					
				//is sample file 
				}else if(quit){
					window.location = "./index.php";
				}
			}
			
			function saveXML(xml, quit){
				new Ajax.Request("./scripts/parseXML.php",{
					method:"post",
					parameters:{"folder":uniqueFolder, "xml":xml},
					onSuccess: function(ajax){
						if (quit) {
							window.location = "./results.php?id="+uniqueFolder + "&checker=" + checker;
						}
					},
					onFailure: function(ajax){
						alert("There was a problem with the Ajax request");
					}
				});
			}
			
			function parseParameters(paramArray){
				var paramMap = new Array();
				for(var i = 0; i < paramArray.length; i++){
					var param = paramArray[i].split("=");
					paramMap[param[0]] = param[1];
				}
				return paramMap;
			}
        </script>
    </head>
<?php
   // include("./scripts/header.php");
?>
    <body style="background-image:url(./resources/PipeJamBackground.jpg);background-repeat:all;margin-top:20px;margin-bottom:20px;">
        <div id="swf_container" style="width:1024px;height:768px;margin-left:auto;margin-right:auto;">
    
            <!-- SWFObject's dynamic embed method replaces this alternative HTML content with Flash content when enough 
    			 JavaScript and Flash plug-in support is available. The div is initially hidden so that it doesn't show
    			 when JavaScript is disabled.
    		-->
            <div id="flashContent" >
            	<p>
    	        	To view this page ensure that Adobe Flash Player version 
    				10.0.0 or greater is installed. 
    			</p>
    			<script type="text/javascript"> 
    				var pageHost = ((document.location.protocol == "https:") ? "https://" :	"http://"); 
    				document.write("<a href='http://www.adobe.com/go/getflashplayer'><img src='" 
    								+ pageHost + "www.adobe.com/images/shared/download_buttons/get_flash_player.gif' alt='Get Adobe Flash player' /></a>" ); 
    			</script> 
            </div>
    	   	<br /><br /><span id="text_area"></span>
    	   	<script>
    	   		if(debug){
    				var debugArea = "<textarea rows=15 id=\"debug\" style=\"background-color:gray; text-align:left; width: 75%;\"></textarea>";
    				document.getElementById("text_area").innerHTML = debugArea;
    			}
    	   	</script>
    	<noscript>
                <object classid="clsid:D27CDB6E-AE6D-11cf-96B8-444553540000" width="100%" height="768" id="Game">
                    <param name="movie" value="Game.swf" />
                    <param name="quality" value="high" />
                    <param name="bgcolor" value="#ffffff" />
                    <param name="allowScriptAccess" value="sameDomain" />
                    <param name="allowFullScreen" value="true" />
                    <!--[if !IE]>-->
                    <object type="application/x-shockwave-flash" data="Game.swf" width="100%" height="768">
                        <param name="quality" value="high" />
                        <param name="bgcolor" value="#ffffff" />
                        <param name="allowScriptAccess" value="sameDomain" />
                        <param name="allowFullScreen" value="true" />
                    <!--<![endif]-->
                    <!--[if gte IE 6]>-->
                    	<p> 
                    		Either scripts and active content are not permitted to run or Adobe Flash Player version
                    		10.0.0 or greater is not installed.
                    	</p>
                    <!--<![endif]-->
                        <a href="http://www.adobe.com/go/getflashplayer">
                            <img src="http://www.adobe.com/images/shared/download_buttons/get_flash_player.gif" alt="Get Adobe Flash Player" />
                        </a>
                    <!--[if !IE]>-->
                    </object>
                    <!--<![endif]-->
                </object>
    	    </noscript>		
    	 </div>
	 </body>
</html>
<?php
   // include("./scripts/footer.php");
?>
