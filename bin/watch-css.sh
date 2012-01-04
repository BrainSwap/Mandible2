#!/bin/sh
# Watch for changes in sass files and render them to CSS files.
sass --style=expanded --watch ../src/scss:../deploy-debug/css