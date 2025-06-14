# BOPS

![CI](https://github.com/unboxed/bops/actions/workflows/build.yml/badge.svg) ![CodeQL](https://github.com/unboxed/bops/workflows/CodeQL/badge.svg)

[FAQs](docs/FAQs.md)
[Architecture overview](docs/architecture.md)

## Back-Office Planning System (BOPS)

This README is aimed at developers wishing to work on this project or learn more about the code base in this repository. If you need technical guidance for getting set up on BOPS, contact us [here](mailto:bops-team@unboxedconsulting.com).

## Getting started

### Using Docker

The easiest way to run the application is with Docker.

If it's your first time setting up the project or you are changing the docker file first run:

```sh
docker compose build 
```

Then build and launch the images:

```sh
docker-compose up
```

Once the containers are running, use the Makefile to get a prompt and set up the database:

```sh
make prompt

root@232515c34d14:/app# bin/rails db:setup
```

It may also be necessary to install yarn and precompile the Rails assets:

```sh
make prompt

yarn install

bin/rails assets:precompile
```

## Building production docker

### Create production docker

```sh
docker build -t bops -f Dockerfile.production .
```

### Run production docker

```sh
docker run --rm -it -p 3000:3000 -e DATABASE_URL=postgres://postgres@host.docker.internal:5432/bops_development -e RAILS_SERVE_STATIC_FILES=true -e RAILS_ENV=production -e RAILS_LOG_TO_STDOUT=true bops:latest bundle exec rails s
```

### Run production docker bash

```sh
docker run --rm -it -e DATABASE_URL=postgres://postgres@host.docker.internal:5432/bops_development -e RAILS_SERVE_STATIC_FILES=true -e RAILS_ENV=production -e RAILS_LOG_TO_STDOUT=true bops:latest /bin/bash
```

### Run BOPS locally

#### Install the project's dependencies:

```sh
$ bundle install
$ yarn install
$ brew install chromedriver  # as an admin user
```

It is necessary to have PostgreSQL installed and the PostGIS extension enabled.

#### Enable the PostGIS extension:

If enabling PostGIS natively, please review the [installation guide](https://postgis.net/documentation/getting_started/).

#### Create the databases

```sh
$ rails db:setup
```

#### Start the server:

```sh
$ bin/dev
```

## Subdomains

Because of the local authority being inferred on the request's subdomain,
options to get the application working locally include using Docker or
using the `bops.localhost` domain which points back to localhost:

```
http://southwark.bops.localhost:3000/
http://lambeth.bops.localhost:3000/
http://buckinghamshire.bops.localhost:3000/
```

This should happen automatically but may require adding the hosts to `/etc/hosts`
if a specific system/browser config doesn't work.

## GOV.UK Notify

The staging and production environments need keys generated by [GOV.UK Notify](https://www.notifications.service.gov.uk/sign-in), which is a government service that enables the bulk secure sending of emails, SMS and letters. To run the application locally, set an environment variable `NOTIFY_API_KEY` which should contain a mock value.

### 2FA

To enable 2FA in development, set the keys for `OTP_SECRET_ENCRYPTION_KEY` and `NOTIFY_API_KEY`, and set `otp_required_for_login` to `true` on the user. This can be found in 1password and within your GOV.UK Notify Notify account

These keys are set within [github actions](https://github.com/unboxed/bops/settings/secrets/actions) for our testing and CI builds

Versions 5+ of the [devise-two-factor](https://github.com/tinfoil/devise-two-factor) gem uses a single [Rails 7+ encrypted attribute](https://edgeguides.rubyonrails.org/active_record_encryption.html) named `otp_secret` to store the OTP secret in the database table

See the [BOPS Terraform](https://github.com/unboxed/bops-terraform) repo for more information about BOPS infrastructure.

## OS maps

To utilise all the map functionality, set an `OS_VECTOR_TILES_API_KEY` in `.env`
This value can be found in the AWS Parameter Store

## API

## Creating data through the API

Once the application is running, planning applications can be submitted through the API.

API documentation is available at /api/docs/index.html.

Do this through the provided Swagger documentation at /api/docs/index.html

* Click Authorize and fill in the API key (both v1 and v2 are scoped per user and thus to local authority)
* POST /api/v1/planning_applications > Try it out > Choose 'Full' example > Click Execute.

[1]: https://www.docker.com/products/docker-desktop
[2]: http://localhost:3000/

## Working with API documentation: aggregate Swagger files

To keep the code easy to maintain, there are multiple files that are compiled into a single OpenAPI file:

```
public/api/docs/v1/swagger_doc.yaml
```

So to create a new API endpoint, create the yaml doc inside swagger/v1 and reference it in:

```
swagger/v1/swagger_doc.yaml
```

like so:

```
  $ref: "./your_new_file_name.yaml"
```

Make changes to the new file and aggregate them into a single file by installing this package locally:

```
npm install -g swagger-cli
```

and running:

```
swagger-cli bundle swagger/v1/swagger_doc.yaml --outfile public/api/docs/v1/swagger_doc.yaml --type yaml --dereference
```

## Maps

- We are using an open-source [npm package](https://github.com/theopensystemslab/map/tree/main/src) by [OSL](https://www.opensystemslab.io/) to render all of our maps
- This is an [OpenLayers](https://openlayers.org/)-powered [Web Component](https://developer.mozilla.org/en-US/docs/Web/Web_Components) map for tasks related to planning permission in the UK.

## JavaScript

We are using [Stimulus](https://stimulus.hotwired.dev) to handle our minimal JavaScript requirements.

After adding a new Stimulus controller run `./bin/rails stimulus:manifest:update`. Alternatively create the controller with `./bin/rails generate stimulus controllerName`.

## Front-end components

As much as possible, we follow the GOV.UK Design System. The HTML components can be found here [here](https://design-system.service.gov.uk/get-started). For help with forms we use the [GOV.UK Ruby on Rails Form Builder gem](https://govuk-form-builder.netlify.app). See [here](https://github.com/unboxed/bops/blob/main/app/views/users/_form.html.erb) for a simple example of implementation.

## Creating users

The seed file will automatically create and confirm users for each role and subdomain as well as a global admin user. You will need to update the password for this user. 
