#!/bin/bash

# export JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk1.7.0_06.jdk/Contents/Home
export DIST_DIR=/Users/rigsby/verigames/java/dist
export SCALA_LIB=/usr/local/Cellar/scala/2.9.2/libexec/lib/

SCALA_LIBS=("scala-library.jar" "scala-compiler.jar")

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

$JAVA_HOME/bin/java -Dscala.usejavacp=true -Xms512m -Xmx1024m \
"-Xbootclasspath/p"$BCP \
-ea checkers.inference.TTIRun --checker nninf.NninfChecker --visitor nninf.NninfVisitor \
--solver nninf.NninfGameSolver $1