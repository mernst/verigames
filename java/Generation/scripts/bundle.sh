# The production version is at
# /homes/abstract/bdwalker/www/java/verigames.jar

# We are in the scripts directory
mydir=`dirname $0`

# the root (all-projects) is up 4 levels

root=`cd $mydir/../../../..; pwd`
# echo $root

tmp=/tmp
jar=$VERIGAMESJAR

echo Make sure all projects are built!
echo Creating $jar

# rm $jar

cd $root/jsr308-langtools/build/classes
jar -uf $jar `find . -name "*.class"` `find . -name "*.properties"` 

cd $root/checker-framework/checkers/build
jar -uf $jar `find . -name "*.class"` `find . -name "*.properties"` 

cd $root/checker-framework/javaparser/build
jar -uf $jar `find . -name "*.class"`

cd $root/annotation-tools/annotation-file-utilities/bin
jar -uf $jar `find . -name "*.class"`

cd $root/annotation-tools/scene-lib/bin
jar -uf $jar `find . -name "*.class"`

cd $root/annotation-tools/asmx/bin
jar -uf $jar `find . -name "*.class"`

cd $root/annotation-tools/scene-lib/bin
jar -uf $jar `find . -name "*.class"`

cd $root/plume-lib/bin-eclipse
jar -uf $jar `find . -name "*.class"`

cd $root/checker-inference/bin
jar -uf $jar `find . -name "*.class"`

cd $root/verigames/java/Generation/bin
jar -uf $jar `find . -name "*.class"`

cd $root/verigames/java/Translation/bin
jar -uf $jar `find . -name "*.class"`

