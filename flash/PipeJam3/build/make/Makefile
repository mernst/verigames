MXMLC := "${FLEX_HOME}"/bin/mxmlc +FLEX_HOME="${FLEX_HOME}"
SWFINFO := ../../external/swfinfo/bin/swfinfo -html

.PHONY: prebuild check install test debug release all

all: debug release

debug: bin/debug/PipeJam3.swf

release:

check:
ifndef FLEX_HOME
	$(error FLEX_HOME needs to be set)
endif

prebuild: check
	cd ../.. && python script/prebuild.py

bin/debug/PipeJam3.swf: prebuild
	${MXMLC} -load-config+=config-base.xml -load-config+=config-debug.xml -load-config+=config-web.xml ../../src/PipeJam3.as -o $@
	${SWFINFO} $@ > $(basename $@).html

install:
ifndef PREFIX
	$(error PREFIX needs to be set)
endif
	cp -R bin ${PREFIX}

clean:
	rm -rf bin
