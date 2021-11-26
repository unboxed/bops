FROM ruby:2.6.6

# Match our Bundler version
RUN gem install bundler -v 2.2.7

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
RUN curl -fsSL https://deb.nodesource.com/setup_14.x | bash -
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

COPY . .

CMD ["bundle", "exec", "rails", "s", "-b", "0.0.0.0"]
