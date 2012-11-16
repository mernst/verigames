#!/bin/bash 

export CLASSPATH=$JSR308/verigames/java/verigames.jar


export jsr308_imports=checkers.interning.quals.*:checkers.nullness.quals.*:checkers.regex.quals.*:checkers.signature.quals.*
export JAVA_OPTS="-Xdebug -Xrunjdwp:transport=dt_socket,server=y,suspend=y,address=5005 -ea -server -Xmx1024m -Xms512m -Xss1m -Xbootclasspath/p:$CLASSPATH"

#export JAVA_OPTS="-ea -server -Xmx1024m -Xms512m -Xss1m -Xbootclasspath/p:$CLASSPATH"

ME=`basename $0`

   $SCALA -cp $CLASSPATH checkers.inference.TTIRun --checker $1 --visitor $2 --solver $3 "${@:3}";
