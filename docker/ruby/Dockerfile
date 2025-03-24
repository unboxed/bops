ARG RUBY_VERSION=3.4.1

FROM ruby:$RUBY_VERSION-bookworm

ENV BUNDLE_PATH=/home/rails/bundle

# Run security updates and install apt-utils curl and locales
RUN bash -c "export DEBIAN_FRONTEND=noninteractive && \
    apt-get update -qq && \
    echo 'en_US.UTF-8 UTF-8' > /etc/locale.gen && \
    apt-get install -y apt-utils curl locales && \
    apt-get upgrade -y && apt-get clean"

# Install system packages
RUN bash -c "apt-get install -y --no-install-recommends libvips-dev poppler-utils"

# Install PostgreSQL client
RUN bash -c "echo 'deb http://apt.postgresql.org/pub/repos/apt/ bookworm-pgdg main' \
    > /etc/apt/sources.list.d/pgdg.list && \
    wget -q -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc \
    | apt-key add - && apt-get update && \
    apt-get install -y --no-install-recommends postgresql-client-16"

# Install NodeJS
ARG NODE_VERSION=20.11.0
ARG YARN_VERSION=1.22.19
ARG SWAGGER_CLI_VERSION=4.0.4
ENV PATH=/usr/local/node/bin:$PATH
RUN bash -c "curl --retry 5 --retry-delay 5 --retry-max-time 60 -sL https://github.com/nodenv/node-build/archive/master.tar.gz | tar xz -C /tmp/ && \
    /tmp/node-build-master/bin/node-build '$NODE_VERSION' /usr/local/node && \
    npm install -g yarn@$YARN_VERSION && \
    npm install -g swagger-cli@$SWAGGER_CLI_VERSION && \
    rm -rf /tmp/node-build-master"

# Install Bundler
ARG BUNDLER_VERSION=2.5.3
RUN bash -c "gem update --system && gem install bundler -v $BUNDLER_VERSION"

# Install Chromium and Chromium-Driver
RUN bash -c "apt-get install -y --no-install-recommends chromium chromium-driver"

# Copy entrypoint script that ensures gems and packages are installed
COPY ./docker-entrypoint.sh /bin/docker-entrypoint.sh

# Set working directory
WORKDIR /home/rails

# Create user and setup permissions
RUN bash -c "groupadd -r rails && \
    useradd --no-log-init -r -g rails -d /home/rails rails && \
    mkdir -p /home/rails/bundle && \
    mkdir -p /home/rails/bops/node_modules && \
    chown -R rails:rails /home/rails && \
    chmod go-rx /home/rails"

# Create the crash reports directory - without it Chromium complains on startup
RUN bash -c "mkdir -p /home/rails/.config/chromium/Crash Reports/pending/ && \
    chown -R rails:rails /home/rails/.config"

# Switch to non-root user
USER rails:rails

# Mark the bops directory as safe so that lint tasks don't complain
RUN bash -c "git config --global --add safe.directory /home/rails/bops"

ENTRYPOINT ["/bin/docker-entrypoint.sh"]
CMD ["/bin/bash"]
