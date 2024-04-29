#!/bin/sh
set -e

NODE_VERSION=$(cat .node-version)
if ! grep -q "^ARG NODE_VERSION=$NODE_VERSION" docker/ruby/Dockerfile; then
	echo "Dockerfile has wrong node: $(grep '^ARG NODE_MAJOR' docker/ruby/Dockerfile)" >&2
	exit 1
fi
if ! grep -q "^ARG NODE_VERSION=$NODE_VERSION" Dockerfile.production; then
	echo "Dockerfile.production has wrong node: $(grep '^ARG NODE_MAJOR' Dockerfile.production)" >&2
	exit 1
fi

RUBY_VERSION=$(cat .ruby-version)
if ! grep -q "^ARG RUBY_VERSION=$RUBY_VERSION" docker/ruby/Dockerfile; then
	echo "Dockerfile has wrong ruby: $(grep '^FROM ruby:' docker/ruby/Dockerfile)" >&2
	exit 1
fi
if ! grep -q "^ARG RUBY_VERSION=$RUBY_VERSION" Dockerfile.production; then
	echo "Dockerfile.production has wrong ruby: $(grep '^ARG RUBY_VERSION' Dockerfile.production)" >&2
	exit 1
fi
