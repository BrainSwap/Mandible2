UGLIFY=vendor/uglifyjs
REMOVE_DEBUG_CODE=bin/remove-debug-code.sh

JS_FILES=dev/js/vendor/jquery.js\
dev/js/vendor/underscore.js\
dev/js/index.js

CSS_FILES=dev/scss/index.scss\
dev/scss/_mixins.scss\
dev/scss/_html5boilerplate.scss\
dev/scss/_base.scss\
dev/scss/_page-home.scss\
dev/scss/_ipad.scss\
dev/scss/_iphone.scss\
dev/scss/_mobile-landscape.scss\
dev/scss/_mobile-portrait.scss\
dev/scss/_tablet-portrait.scss

JS_OUTPUT_FILE=prod/js/index.js

# Compress source files
all: prod/js/index.js prod/css/index.css prod/index.html

# Compress version
prod/js/index.js : ${JS_FILES}
	@echo 'JS file is out of date. Compiling...'
	if [ ! -f ${JS_OUTPUT_FILE} ]; then touch ${JS_OUTPUT_FILE}; fi
	cat ${JS_FILES} > tmp
	${REMOVE_DEBUG_CODE} tmp
	cat dev/js/debug.js >> tmp
	${UGLIFY} tmp > ${JS_OUTPUT_FILE}
	rm tmp;

prod/css/index.css : ${CSS_FILES}
	@echo 'CSS file is out of date. Compiling...'
	echo ${CSS_FILES}
	sass --update --style=compressed dev/scss/:prod/css

prod/index.html : src/index.html
	@echo 'HTML files are out of date. Compiling...'
	cd bin; ./watch-template.sh --no-watch

# debug compressed js
debug:
	cat ${JS_FILES} > tmp
	cat tmp > ${JS_OUTPUT_FILE}
	rm tmp;