# BOPS ![CI](https://github.com/unboxed/bops/workflows/CI/badge.svg)

Back Office Planning System (BOPS)

## Getting started

### Using Docker

First build and launch the images:

```sh
docker-compose up
```

Once your containers are running, you can use the Makefile to get a
prompt and setup your database:

```sh
make prompt

root@232515c34d14:/app# bin/rails db:setup
```

### Locally

#### Install the project's dependencies:

```sh
$ bundle install
$ yarn install
```

#### Create the databases

```sh
$ rails db:setup
```

#### Start the server:

```sh
$ rails server
```

## Subdomains

Because of the local authority being inferred on the request's
subdomain, your options to get work locally include using Docker or
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

To enable 2FA in development, you must set the env variable `2FA_ENABLED` to `true` and set the keys for `OTP_SECRET_ENCRYPTION_KEY` and `NOTIFY_API_KEY`. You may find this in 1password and within your GOV.UK Notify notify account

These keys are set within [github actions](https://github.com/unboxed/bops/settings/secrets/actions) for our testing and CI builds


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
swagger-cli bundle public/api-docs/v1/swagger_doc.yaml --outfile public/api-docs/v1/_build/swagger_doc.yaml --type yaml
```

## Javascript

We are using [Stimulus](https://stimulus.hotwired.dev) to handle our minimal JavaScript requirements.

After adding a new Stimulus controller run `./bin/rails stimulus:manifest:update`. Alternatively you can create the controller with `./bin/rails generate stimulus controllerName`.


## Front end components

As much as possible, we follow the GOV.UK Design System. You will find most of the HTML components you need [here](https://design-system.service.gov.uk/get-started). For help with forms we use the [GOV.UK Ruby on Rails Form Builder gem](https://govuk-form-builder.netlify.app). See [here](https://github.com/unboxed/bops/blob/main/app/views/users/_form.html.erb) for a simple example of implementation.

## Environmental variables

Environmental variables are defined in the [bops-terraform project using Ansible](https://github.com/unboxed/bops-terraform/blob/main/ansible/templates/app/etc/default/application.j2).
Here the lookup call matches [AWS parameter store](https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-parameter-store.html) 
keys whose values will become set as environmental variables.

In this case ansible_env can typically be preview or production. So, the first row ends up looking up the key "/bops/preview/PAAPI_URL".

```python
PAAPI_URL={{ lookup('aws_ssm', '/bops/' + ansible_env + '/PAAPI_URL', region=aws_region) }}   # 1
PLANNING_HISTORY_ENABLED={{ lookup('aws_ssm', '/bops/' + ansible_env + '/PLANNING_HISTORY_ENABLED', region=aws_region) }} # 2
```

## AWS Parameter store is a key value pair store

The lookup will return the value associated with the key; in the case of example 1 that is: "https://example.services/api/v1".

| Key                                     |   String Value                        |
| ------------------------------------------------------------------------------- |
| /bops/preview/PAAPI_URL                 |   https://example.services/api/v1     |
| /bops/preview/PLANNING_HISTORY_ENABLED  |   true                                |

So on the system we will have the following ENV variable:

`PAAPI_URL=https://example.services/api/v1`

### Changing Environmental variables

If we wish to make a change to the ENV variables on the server. 
First we change the Ansible script and adding a Key/value pair to the AWS Parameter store.
Then refresh the server instance by running from the BoPS terraform application.
The servers should now have the new Environment variable.

```bin/start-instance-refresh preview```
