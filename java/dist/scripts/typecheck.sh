#!/bin/bash

thisDir="`dirname $0`"
case `uname -s` in
    CYGWIN*)
      thisDir=`cygpath -m $mydir`
      ;;
esac

export DIST_DIR=$thisDir"/.."

CF_JAR=$DIST_DIR"/checkers.jar"
#DIST_LIBS=("checker-framework-inference.jar" "verigames.jar")
DIST_LIBS=("javac.jar" "jdk7.jar" "checker-framework-inference.jar"
           "checkers.jar" "annotation-file-utilities.jar" "javaparser.jar"
           "verigames.jar")

CP="."
for i in "${DIST_LIBS[@]}"
do
    CP=$CP":"$DIST_DIR"/"$i  	
done


if [[ ! -z "$DEBUG" ]]; then
    echo "debugging"
    JAVA_OPTS="-Xdebug -Xrunjdwp:transport=dt_socket,server=y,suspend=y,address=5005 -ea -server -Xmx1024m -Xms512m -Xss1m"
fi

CMD=$JAVA_HOME"/bin/java $JAVA_OPTS -jar "$CF_JAR" -cp "$CP" "$@
echo "Executing "$CMD
eval $CMD
