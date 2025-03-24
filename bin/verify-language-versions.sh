#!/bin/sh
set -e

EXIT=0

NODE_VERSION=$(cat .node-version)
RUBY_VERSION=$(cat .ruby-version)

for dockerfile in docker/ruby/Dockerfile Dockerfile.production; do
	if ! grep -q "^ARG NODE_VERSION=$NODE_VERSION" $dockerfile; then
		echo "$dockerfile has wrong node: $(grep '^ARG NODE_MAJOR' $dockerfile)" >&2
		EXIT=1
	fi

	if ! grep -q "^ARG RUBY_VERSION=$RUBY_VERSION" $dockerfile; then
		echo "$dockerfile has wrong ruby: $(grep '^FROM ruby:' $dockerfile)" >&2
		EXIT=1
	fi
done

exit $EXIT
