#!/bin/bash

# fail on any failed command
set -e

echo "running xmllint..."
xmllint -valid -noout $1

echo "running Java validator..."
java -cp ./bin:./lib/xom-1.2.10.jar verigames.level.XMLValidator < $1

echo "no errors detected"
