#!/bin/bash

set -e

echo 'Waiting for a connection with postgres...'

until psql -h "postgres" -U "postgres" -c '\q' > /dev/null 2>&1; do
  sleep 1
done

echo "Connected to postgres..."

echo "Bundling gems"
bundle check || bundle install

echo "Creating the database..."
bundle exec rails db:create
echo "Migrating the database..."
bundle exec rails db:migrate
echo "Seed data to the database..."
bundle exec rails db:seed
echo "Create sample  the database..."
bundle exec rails create_sample_data

if [ "$2" == 'server' ]; then
  if [ -f /app/tmp/pids/server.pid ]; then
    echo 'Deleting old server pid file ...'
    rm -f /app/tmp/pids/server.pid
  fi
fi

# parameters will pass to bundle exec from docker-compose
bundle exec "$@"
