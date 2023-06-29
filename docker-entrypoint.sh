#!/bin/bash

set -e

echo "Initializing BOPS"
echo "Bundling gems"
bundle check || bundle install

if [ -f /app/tmp/pids/server.pid ]; then
	echo 'Deleting old server pid file ...'
	rm -f /app/tmp/pids/server.pid
fi

yarn install

# parameters will pass to bundle exec from docker-compose
bundle exec "$@"
