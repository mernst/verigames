#!/bin/bash

thisDir="`dirname $0`"
case `uname -s` in
    CYGWIN*)
      thisDir=`cygpath -m $mydir`
      ;;
esac

distDir=$thisDir"/../../../dist"
exampleDir=$thisDir"/../../examples"

#For every java file in "java/Generation/examples" run inferNullness.sh
#and after all finish exit 0 if none failed or 1 if any had a non-zero exit status

files=(`find $exampleDir -name "*.java"`) 

success=true
count=0
failed=0
passed=0
for f in "${files[@]}"
do
	
	#create dot string for fileName.......status!
	length="${#f}"
	numDots=`expr 60 - ${length}`
	dots=""
	if [ $length -lt 40 ]
	then
        for i in $(seq 1 $numDots)
		do 
    		dots=$dots"." 
		done
	fi
	
	
	eval sh $distDir"/scripts/inferNullness.sh "$f
	
	if [ $? -ne 0 ]
		then  
			files[$count]=$f$dots"failed!"
			success=false
			failed=`expr ${failed} + 1`
		else 
			files[$count]=$f$dots"passed!"
			passed=`expr ${passed} + 1`
	fi
	
    count=`expr ${count} + 1`
    
	echo ""
	echo "========================================"
	echo ""
done

echo ""
echo "Results:"
for f in "${files[@]}"
do
	echo $f
done

echo "Total Files: "$count" Passed: "$passed" Failed: "$failed

if $success ; 
	then
    	echo 'Success!'
		echo ""
    else
    	echo 'Failed!'
		echo ""
    	exit 1
fi