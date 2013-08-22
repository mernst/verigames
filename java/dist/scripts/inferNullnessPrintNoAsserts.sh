#!/bin/bash

thisDir="`dirname $0`"
case `uname -s` in
    CYGWIN*)
      thisDir=`cygpath -m $mydir`
      ;;
esac

sh $thisDir"/inferencePrint.sh" -da checkers.inference.TTIRun --checker nninf.NninfChecker --visitor nninf.NninfVisitor \
--solver nninf.NninfGameSolver $@
