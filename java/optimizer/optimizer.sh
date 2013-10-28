#!/bin/bash

DIR="$(dirname "$0")"
JAR="$DIR/build/libs/optimizer.jar"

if [ ! -e "$JAR" ]; then
    echo "Failed to find $JAR... try running 'gradle jar' in $DIR"
    exit 1
fi

pushd "$DIR" >/dev/null
CP="$JAR:$(gradle -q printRuntimeClasspath | tail -n1):$CLASSPATH"
popd >/dev/null
exec java -cp "$CP" verigames.optimizer.Main $@
