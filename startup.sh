#!/bin/bash

set -e

echo 'db:create'
bundle exec rake db:create

echo 'db:migrate'
bundle exec rake db:migrate

echo 'db:seed'
bundle exec rails db:seed

echo 'create_sample_data'
bundle exec rails create_sample_data

bundle exec "$@"
