MXMLC := "${FLEX_HOME}"/bin/mxmlc +FLEX_HOME="${FLEX_HOME}" -debug=true -incremental=false -benchmark=false -static-link-runtime-shared-libraries=true -verbose-stacktraces=true -locale en_US -managers=flash.fonts.AFEFontManager

.PHONY: prebuild web

all: web

web: bin/web/PipeJam3.swf

check:
ifndef FLEX_HOME
	$(error FLEX_HOME needs to be set)
endif

prebuild: check
	cd ../.. && python script/prebuild.py

bin/web/PipeJam3.swf: prebuild
	${MXMLC} -load-config+=config-web.xml ../../src/PipeJam3.as -o $@

clean:
	rm -rf bin
