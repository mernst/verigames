#!/bin/bash 

#. $JSR308/checker-framework-inference/scripts/setup.sh
#export JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk1.7.0_06.jdk/Contents/Home

#export JAVAC=$JSR308/jsr308-langtools/dist/bin/javac
#export CHECKERS=$ROOT/checker-framework/checkers

# ensures that the JSR308 javac uses the JDK7 java
#export PATH=$JAVA_HOME/bin:$PATH
#export JAVA=$JAVA_HOME/bin/java

#export SCALA=$SCALA_HOME/bin/scala
#export CLASSPATH=$JSR308/verigames/java/verigames.jar


export jsr308_imports=checkers.interning.quals.*:checkers.nullness.quals.*:checkers.regex.quals.*:checkers.signature.quals.*
#export JAVA_OPTS="-Xdebug -Xrunjdwp:transport=dt_socket,server=y,suspend=y,address=5005 -ea -server -Xmx1024m -Xms512m -Xss1m -Xbootclasspath/p:$CLASSPATH"

export JAVA_OPTS="-ea -server -Xmx1024m -Xms512m -Xss1m -Xbootclasspath/p:$CLASSPATH"

ME=`basename $0`

   $SCALA -cp $CLASSPATH checkers.inference.TTIRun --checker $1 --visitor $2 --solver $3 "${@:3}";
