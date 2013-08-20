#!/bin/bash

thisDir="`dirname $0`"
case `uname -s` in
    CYGWIN*)
      thisDir=`cygpath -m $mydir`
      ;;
esac

sh $thisDir"/inference.sh" -agentlib:jdwp=transport=dt_socket,server=y,suspend=y,address=5005  checkers.inference.TTIRun --checker nninf.NninfChecker --visitor nninf.NninfVisitor \
--solver nninf.NninfGameSolver $@
