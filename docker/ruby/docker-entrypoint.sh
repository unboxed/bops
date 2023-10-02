#!/bin/bash

set -e

if [ "$1" = "bash" ]; then
  exec "$@"
else
  yarn install
  bundle check || bundle install

  bundle exec "$@"
fi
