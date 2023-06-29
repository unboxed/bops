FROM ruby:3.2.2

# Match our Bundler version
RUN gem install bundler -v 2.3.26

# Update the system
RUN apt-get update -y

# Install Chromium for the feature tests
RUN apt-get install -y --no-install-recommends chromium

# Install Poppler to generate PDF previews
RUN apt-get install -y --no-install-recommends poppler-utils

## Install gems in a separate Docker fs layer
WORKDIR /gems
COPY Gemfile Gemfile.lock ./
RUN bundle

## Node
ARG NODE_MAJOR=16
RUN curl -fsSL https://deb.nodesource.com/setup_$NODE_MAJOR.x | bash -
RUN apt-get install -y nodejs

## Yarn
RUN curl -sL https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
RUN apt-get update && apt-get install yarn

## Install yarn dependencies in a separate Docker fs layer
WORKDIR /js
COPY package.json yarn.lock ./
RUN yarn install

WORKDIR /app

RUN mkdir -p node_modules .cache
RUN groupadd -r app && \
    useradd --no-log-init -r -g app -d /app app
RUN chown -R app:app node_modules .cache

USER app:app

COPY . .


# Sets an interactive shell as default command when the container starts
CMD ["/bin/sh"]
