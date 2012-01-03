#!/bin/sh

# Watches both templates and CSS files by running this script.
# Ctr-c to stop.

kill_background_processes() {
    kill $template_watch_pid $sass_pid
}
trap kill_background_processes SIGINT SIGTERM

# Watch for js template changes.
./watch-template.sh &
template_watch_pid=$!

# Watch for changes in sass files and render them to CSS files.
sass --watch --style=compressed ../dev/scss:../prod/css &
sass_pid=$!

wait $template_watch_pid $sass_pid