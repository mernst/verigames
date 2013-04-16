#!/bin/bash

thisDir="`dirname $0`"
case `uname -s` in
    CYGWIN*)
      thisDir=`cygpath -m $mydir`
      ;;
esac

export DIST_DIR=$thisDir"/.."

CF_JAR=$DIST_DIR"/checkers.jar"
DIST_LIBS=("checker-framework-inference.jar" "verigames.jar")

CP="."
for i in "${DIST_LIBS[@]}"
do
    CP=$CP":"$DIST_DIR"/"$i  	
done


CMD=$JAVA_HOME"/bin/java -jar "$CF_JAR" -cp "$CP" "$@
echo "Executing "$CMD
eval $CMD