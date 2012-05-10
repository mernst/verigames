<?php

if(isset($_REQUEST["function"]) && isset($_REQUEST["id"])) {
    $function = $_REQUEST["function"];
    $id = $_REQUEST["id"];
    
    if(!strcmp($function, "zip")) {
        $result = zipFiles($id);
    }
    
    if($result) 
        print("SUCCESS");
    else
        print("Error executing: ". $function);
    
} else {
    print("Must pass both a function and an id");
}



function zipFiles($id) {
    chdir('/homes/abstract/bdwalker/www/live/uploads/'. $id);
    exec('zip -v results.zip `find ./inference-output/*.java ./inference-output/*/*.java` >> zip_output.txt');
    if(file_exists("results.zip")) {
        return True;
    } else {
        exec('zip -v results.zip `find -wholename ./inference-output/*.java`');
    }
    
    if(file_exists("results.zip")) {
        return True;
    } else {
        return False;
    }
}


?>