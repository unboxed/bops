#!/bin/bash

set -e

echo 'Waiting for a connection with postgres...'

until psql -h "postgres" -U "postgres" -c '\q' > /dev/null 2>&1; do
  sleep 1
done

echo "Connected to postgres..."

echo "Bundling gems"
bundle check || bundle install

if [ -z ${DATABASE_URL+x} ]; then
  echo "Skipping database setup"
else
  echo "Checking database setup is up to date"
  # Rails will throw an error if no database exists"
  if bundle exec rails db:migrate:status &> /dev/null; then
    echo "Database found"
    if bundle exec rails db:migrate:status | grep "^\s*down"; then
      echo "Running db:migrate"
      bundle exec rails db:migrate
    else
      echo "No pending migrations found."
    fi
  else
    echo "Runs db:create, db:schema:load and db:seed."
    bundle exec rails db:setup
    echo "Create sample  the database."
    bundle exec rails create_sample_data
  fi
  echo "Finished database setup."
fi

if [ "$2" == 'server' ]; then
  if [ -f /app/tmp/pids/server.pid ]; then
    echo 'Deleting old server pid file ...'
    rm -f /app/tmp/pids/server.pid
  fi
fi

# parameters will pass to bundle exec from docker-compose
bundle exec "$@"
