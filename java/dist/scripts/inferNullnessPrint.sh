#!/bin/bash

thisDir="`dirname $0`"
case `uname -s` in
    CYGWIN*)
      thisDir=`cygpath -m $mydir`
      ;;
esac

sh $thisDir"/inferencePrint.sh" checkers.inference.TTIRun --checker nninf.NninfChecker --visitor nninf.NninfVisitor \
--solver checkers.inference.floodsolver.FloodSolver --transfer nninf.NninfTransferImpl  $@ 
