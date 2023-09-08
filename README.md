# BoPS ![CI](https://github.com/unboxed/bops/workflows/CI/badge.svg)

Back Office Planning System (BoPS)

## Getting started

### Using Docker

First cd into the `bops-applicants` folder and run:

```sh
git submodule update --init --recursive
```

This links it to the BoPS applicants project.

Then build and launch the images:

```sh
docker-compose up
```

Once your containers are running, you can use the Makefile to get a
prompt and setup your database:

```sh
make prompt

root@232515c34d14:/app# bin/rails db:setup
```

You may also need to install yarn and precompile the Rails assets:

```sh
make prompt

yarn install

bin/rails assets:precompile
```

## Building production docker

### Create production docker

```sh
docker build --build-arg RAILS_MASTER_KEY=xxxx -t bops -f Dockerfile.production .
```

### Run production docker

```sh
docker run --rm -it -p 3000:3000 -e DATABASE_URL=postgres://postgres@host.docker.internal:5432/bops_development -e RAILS_SERVE_STATIC_FILES=true -e RAILS_ENV=production -e RAILS_LOG_TO_STDOUT=true bops:latest bundle exec rails s
```

### Run production docker bash

```sh
docker run --rm -it -e DATABASE_URL=postgres://postgres@host.docker.internal:5432/bops_development -e RAILS_SERVE_STATIC_FILES=true -e RAILS_ENV=production -e RAILS_LOG_TO_STDOUT=true bops:latest /bin/bash
```

### Locally

#### Install the project's dependencies:

```sh
$ bundle install
$ yarn install
$ brew install chromedriver  # as an admin user
```

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

Because of the local authority being inferred on the request's
subdomain, your options to get the application working locally include using Docker or
using the `bops-care.link` domain which points back to your localhost:

```
http://southwark.bops-care.link:3000/
http://lambeth.bops-care.link:3000/
http://buckinghamshire.bops-care.link:3000/
```

Otherwise you can use localhost though you'll have to double the
subdomain since `localhost` is missing the second component found in
`normal-domains.com`.

```
http://southwark.southwark.localhost:3000/
http://lambeth.lambeth.localhost:3000/
http://buckinghamshire.buckinghamshire.localhost:3000/
```

## GOV.UK Notify

You should ask for an account to be set up for you on [GOV.UK Notify](https://www.notifications.service.gov.uk/sign-in)

### 2FA

To enable 2FA in development, you must set the keys for `OTP_SECRET_ENCRYPTION_KEY` and `NOTIFY_API_KEY`, and set `otp_required_for_login` to `true` on the user. You may find this in 1password and within your GOV.UK Notify notify account

These keys are set within [github actions](https://github.com/unboxed/bops/settings/secrets/actions) for our testing and CI builds

Versions 5+ of the [devise-two-factor](https://github.com/tinfoil/devise-two-factor) gem uses a single [Rails 7+ encrypted attribute](https://edgeguides.rubyonrails.org/active_record_encryption.html) named `otp_secret` to store the OTP secret in the database table

You will need to add in ./config/credentials a `development.key` (which can be found in 1password) or set a `RAILS_MASTER_KEY` env variable either natively or as part of `docker-compose.yml` with this value to enable 2FA to work in development.

This key is set as an env `RAILS_MASTER_KEY` in production.

## OS maps

To utilise all the map functionality, you will need to set an `OS_VECTOR_TILES_API_KEY` in `.env`
You can find this value from the parameter store on AWS

## BOPS applicants

BOPS allows planning officers to request changes to an application;
these requests are presented to applicants through a separate app
called
[BOPS-applicants](https://github.com/unboxed/bops-applicants). Applicants
receive an email containing a special URL that will be opened in BOPS
applicants and contain the right parameters for it to query back at
BOPS.

If you're using Docker, `bops-applicants` is already part of the
Compose group and should be running on port 3001. If you're not,
you'll have to clone/setup/boot the app manually and point BOPS to it
through the environment variable `APPLICANTS_APP_HOST`. See
`./env.example`.

Another benefit of using Docker is being able to run some end-to-end tests
that integrate both BOPS and BOPS applicants:

```sh
make e2e   # actually runs the Cucumber tests tagged with `@e2e`
```


Note that because of the limitations of Docker network aliases (which
can't accept wildcards, we will add a small DNS service eventually),
BOPS applicants has to operate against the Southwark local authority
(i.e `southwark.localhost`) for now.

## API

API documentation is available at /api-docs/index.html.

## Creating data through the API

Once you have the application running, you can submit planning application through the API. You can do this through the provided swagger documentation at /api-docs/index.html

* Click Authorize and fill in the API key ('123' if not otherwise specified at db:seed)
* POST /api​/v1​/planning_applications > Try it out > Choose 'Full' example > Click Execute.

[1]: https://www.docker.com/products/docker-desktop
[2]: http://localhost:3000/

## Creating a new local authority using a rake take

The following parameters are required and a validation error will be raised if they are not provided:

- `subdomain`: the subdomain to run the service
- `council_code`: should be matched with planning data's code
- `signatory_name`: will be present on decision notice
- `signatory_job_title`: will be present on decision notice
- `enquiries_paragraph`: will be present on decision notice
- `email_address`: will be present on decision notice
- `feedback_email`: will be used to receive any feedback requests

There is also the following optional parameter:

- `admin_email`

```sh
rake local_authority:create -- --subdomain 'lambeth' \
  --council_code 'LBH' \
  --signatory_name 'Bop' \
  --signatory_job_title 'Director of Property' \
  --enquiries_paragraph 'Planning, London Borough of Lambeth' \
  --email_address 'mail@lambeth.gov.uk' \
  --feedback_email 'mail@lambeth.gov.uk' \
  --admin_email 'admin@lambeth.gov.uk'
```

## Working with api documentation: aggregate swagger files

We need a single openapi file to exist, but to keep the code easier to maintain we have multiple files that are then compiled into this single file:

```
public/api-docs/v1/_build/swagger_doc.yaml
```

So to create a new api endpoint, create your yaml doc inside public/api-docs/v1 and reference it in

```
public/api-docs/v1/swagger_doc.yaml
```

like so:

```
  $ref: "./your_new_file_name.yaml"
```

Make changes to your new file, and when you're happy aggregate them into our single file by installing this package in your machine:

```
npm install -g swagger-cli
```

and running:

```
swagger-cli bundle public/api-docs/v1/swagger_doc.yaml --outfile public/api-docs/v1/_build/swagger_doc.yaml --type yaml --dereference
```

## Javascript

We are using [Stimulus](https://stimulus.hotwired.dev) to handle our minimal JavaScript requirements.

After adding a new Stimulus controller run `./bin/rails stimulus:manifest:update`. Alternatively you can create the controller with `./bin/rails generate stimulus controllerName`.


## Front end components

As much as possible, we follow the GOV.UK Design System. You will find most of the HTML components you need [here](https://design-system.service.gov.uk/get-started). For help with forms we use the [GOV.UK Ruby on Rails Form Builder gem](https://govuk-form-builder.netlify.app). See [here](https://github.com/unboxed/bops/blob/main/app/views/users/_form.html.erb) for a simple example of implementation.
