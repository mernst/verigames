#!/bin/bash

thisDir="`dirname $0`"
case `uname -s` in
    CYGWIN*)
      thisDir=`cygpath -m $mydir`
      ;;
esac

export DIST_DIR=$thisDir"/.."
export SCALA_LIB=$DIST_DIR"/scala_lib"

SCALA_LIBS=(`ls $SCALA_LIB`)

DIST_LIBS=("javac.jar" "jdk7.jar" "checker-framework-inference.jar"
           "checkers.jar" "annotation-file-utilities.jar" "javaparser.jar"
           "verigames.jar")

BCP=""
for i in "${DIST_LIBS[@]}"
do
    BCP=$BCP":"$DIST_DIR"/"$i  	
done

for i in "${SCALA_LIBS[@]}"
do
    BCP=$BCP":"$SCALA_LIB"/"$i  	
done

CMD=$JAVA_HOME"/bin/java -DPRINT_WORLD=true -Dscala.usejavacp=true -Xms512m -Xmx1024m -Xbootclasspath/p"$BCP" -ea "$@
echo "Executing "$CMD
eval $CMD