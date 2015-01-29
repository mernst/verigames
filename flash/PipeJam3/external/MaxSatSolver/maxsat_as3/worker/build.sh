AS3COMPILER="asc2.jar"
AS3COMPILERARGS="java -jar ${FLASCC}/usr/lib/${AS3COMPILER} -merge -md"
MXMLC="${FLEX_HOME}/bin/mxmlc +FLEX_HOME=${FLEX_HOME}"

set -e

if [ "$1" = "clean" ]; then
    rm -f maxsat_worker.swf *~
else
    echo "Creating SWF..."
    ${MXMLC} -target-player=11.5 -swf-version=17 -static-link-runtime-shared-libraries=true -library-path+=../util/maxsat_util.swc maxsat_worker.as -o maxsat_worker.swf

    echo "Installing..."
    cp maxsat_worker.swf ../example/lib/
fi
