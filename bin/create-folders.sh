#!/bin/sh
# create default dev folder and sym links
if [ ! -d ../deploy-debug ]; then
    echo "$FILE default dev folder does not exist. Creating it."
	mkdir ../deploy-debug
	ln -s ../src/images ../deploy-debug/images
	ln -s ../src/js ../deploy-debug/js
	ln -s ../src/polyfill ../deploy-debug/polyfill
	mkdir ../deploy-debug/css
fi

