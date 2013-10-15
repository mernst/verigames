#!/bin/bash

thisDir="`dirname $0`"
case `uname -s` in
    CYGWIN*)
      thisDir=`cygpath -m $mydir`
      ;;
esac

export DIST_DIR=$thisDir"/.."

CF_JAR=$DIST_DIR"/checkers.jar"
DIST_LIBS=("javac.jar" "jdk7.jar" "checker-framework-inference.jar"
           "checkers.jar" "annotation-file-utilities.jar" "javaparser.jar"
           "verigames.jar")

CP="."
for i in "${DIST_LIBS[@]}"
do
    CP=$CP":"$DIST_DIR"/"$i  	
done

if [[ -z "$SCALA_HOME" ]]; then
    echo "SCALA_HOME not set. Things might not work correctly."
else
    CP="$CP:$SCALA_HOME/lib/scala-compiler.jar:$SCALA_HOME/lib/scala-library.jar"
fi

# Used by picard to set picard vars.
if [[ ! -z "$CP_EXTRA" ]]; then
    CP="$CP:$CP_EXTRA"
fi

if [[ ! -z "$DEBUG" ]]; then
    echo "debugging"
    JAVA_OPTS="'-J-agentlib:jdwp=transport=dt_socket,server=y,suspend=y,address=5005'"
fi

CMD=$JAVA_HOME"/bin/java -jar "$CF_JAR" -cp "$CP" "$@" "$JAVA_OPTS
echo "Executing "$CMD
eval $CMD
