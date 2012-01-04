UGLIFY=bin/vendor/uglifyjs
REMOVE_DEBUG_CODE=bin/remove-debug-code.sh

JS_FILES=src/js/vendor/jquery.js\
src/js/vendor/underscore.js\
src/js/index.js

CSS_FILES=src/scss/index.scss\
src/scss/_mixins.scss\
src/scss/_html5boilerplate.scss\
src/scss/_base.scss\
src/scss/_page-home.scss\
src/scss/_ipad.scss\
src/scss/_iphone.scss\
src/scss/_mobile-landscape.scss\
src/scss/_mobile-portrait.scss\
src/scss/_tablet-portrait.scss

JS_OUTPUT_FILE=index.js
RELEASE_CODE_ROOT=deploy-prod

# Compress source files
all: deploy-prod/js/index.js deploy-prod/css/index.css deploy-prod/index.html

# Compress version
deploy-prod/js/index.js : ${JS_FILES}
	@echo 'JS file is out of date. Compiling...'
	if [ ! -d ${RELEASE_CODE_ROOT} ]; then mkdir ${RELEASE_CODE_ROOT}; fi
	if [ ! -d ${RELEASE_CODE_ROOT}/js ]; then mkdir ${RELEASE_CODE_ROOT}/js; fi
	if [ ! -f ${RELEASE_CODE_ROOT}/js/${JS_OUTPUT_FILE} ]; then touch ${RELEASE_CODE_ROOT}/js/${JS_OUTPUT_FILE}; fi
	cat ${JS_FILES} > tmp
	${REMOVE_DEBUG_CODE} tmp
	cat src/js/debug.js >> tmp
	${UGLIFY} tmp > ${RELEASE_CODE_ROOT}/js/${JS_OUTPUT_FILE}
	rm tmp;

deploy-prod/css/index.css : ${CSS_FILES}
	@echo 'CSS file is out of date. Compiling...'
	echo ${CSS_FILES}
	sass --update --style=compressed src/scss/:${RELEASE_CODE_ROOT}/css

deploy-prod/index.html : src/index.html
	@echo 'HTML files are out of date. Compiling...'
	cd bin; ./watch-template.sh --no-watch

# debug compressed js
debug:
	cat ${JS_FILES} > tmp
	cat tmp > ${JS_OUTPUT_FILE}
	rm tmp;