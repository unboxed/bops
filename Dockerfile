# Base image
FROM ruby:2.6.5

# Sets an environment variable with the bundle directory
ENV BUNDLE_PATH=/bundle

# Sets an argument variable with the application directory
ARG APP_HOME=/app

# Run security updates
RUN apt-get update && apt-get upgrade -y

# Install curl
RUN apt-get install -y curl

# Install PostgreSQL client
RUN apt-get install -y postgresql-client libpq-dev

# Install Geo libraries
RUN apt-get install -y libgeos-dev libproj-dev gdal-bin

# Install NodeJS 12.x
RUN curl -sL https://deb.nodesource.com/setup_12.x | bash - && \
    apt-get update && apt-get install -y nodejs

# Install Yarn via Debian package repository
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list && \
    apt-get update && apt-get install -y yarn

# The following are used to trim down the size of the image by removing unneeded data
RUN apt-get clean autoclean && \
    apt-get autoremove -y && \
    rm -rf \
    /var/lib/apt \
    /var/lib/dpkg \
    /var/lib/cache \
    /var/lib/log

# Install Bundler
RUN gem install bundler --no-doc

# Create a directory for our application
# and set it as the working directory
WORKDIR $APP_HOME

# Sets an interactive shell as default command when the container starts
CMD ["/bin/sh"]
