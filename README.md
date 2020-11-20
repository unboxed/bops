# BOPS ![CI](https://github.com/unboxed/bops/workflows/CI/badge.svg)

Back Office Planning System (BOPS)

| Dependency | Version |
| ---------- | ------- |
| Ruby       | 2.6.5   |
| Rails      | 6.0.2.2 |
| Postgresql | 1.2.3   |
| Node       | 13.8.0  |
| Yarn       | 1.15.2  |

## Preflight

### Clone the project

```sh
$ git clone git@github.com:unboxed/bops.git
```

## Building the project for local development

We recommend using [Docker Desktop][1] to get setup quickly. If you'd prefer not to use Docker then you'll need to install Ruby (2.6+), Node (10+) and PostgreSQL (9.6+) with PostGIS extension and follow [First Time Setup without using Docker](#first-time-setup-without-using-docker) steps.

### First Time Setup using Docker

#### Create the databases

```sh
$ docker-compose run --rm web rails db:setup
```

#### Seed sample data

```sh
$ docker-compose run --rm web rails create_sample_data
```

#### Start the services

```sh
$ docker-compose up
```

Once the services have started you can access it [here][2].

The default admin credentials are:

| Email address          | Password   | Role       |
| ---------------------- | ---------- | ---------- |
| `assessor@example.com` | `password` | `assessor` |
| `reviewer@example.com` | `password` | `reviewer` |
| `admin@example.com`    | `password` | `admin`    |

#### Tests

You can run the full test suite using following command:

```sh
$ docker-compose run --rm web rake
```

Individual specs can be run using the following command:

```sh
$ docker-compose run --rm web rspec spec/models/user_spec.rb
```

Similarly, individual system specs can be run using the following command:

```sh
$ docker-compose run --rm web rspec spec/system/log_in_spec.rb
```

#### Debugging using `binding.pry`

1. Initially we have installed pry-byebug to development and test group on our Gemfile

```ruby
group :development, :test do
  # ..
  gem 'pry-byebug'
  # ..
end
```

2. Our `docker-compose.yml` in the web container contains the following two line which this will allow shell on a running container:

```bash
web:
  ..
  ..
  tty: true
  stdin_open: true
```

3. Add binding.pry to the desired place you want to have a look on your rails code:

```ruby
def index
  binding.pry
end
```

4. Run your docker app container and get the container id

```sh
$ docker-compose up web
```

5. Open a separate terminal run `docker ps` and to get a list of active containers and get the container id:

```sh
$ docker ps
```

You will get something like that: (65f0b2c36363 is the container id of the web container)

```sh
CONTAINER ID        IMAGE                    COMMAND                  CREATED             STATUS              PORTS                    NAMES
65f0b2c36363        bops_web                 "./docker-entrypoint…"   23 minutes ago      Up 41 seconds       0.0.0.0:3000->3000/tcp   bops_web_1
bc38cc223991        postgis/postgis:latest   "docker-entrypoint.s…"   27 minutes ago      Up 5 minutes        5432/tcp                 bops_postgres_1
```

5. With container id in hand, you can attach the terminal to the docker instance to get your pry on the attached terminal:

```sh
$ docker attach 65f0b2c36363
```

#### Resetting everything

Destroy all containers:

```sh
$ docker-compose down
```

Destroy all containers and volumes: (:warning: This will delete your local databases):

```sh
$ docker-compose down -v
```

### First Time Setup without using Docker

#### Install the project's dependencies using bundler and yarn:

```sh
$ bundle install
$ yarn install
```

#### Enable the PostGIS extension:

Within psql's CLI, enable the postgis and postgis_topology extensions:

```sh
CREATE EXTENSION postgis;
CREATE EXTENSION postgis_topology;
```

#### Create the databases

```sh
$ rails db:setup
```

#### Seed sample data

```sh
$ rails create_sample_data
```

#### Tests

You can run the full test suite using following command:

```sh
$ rspec
```

Individual system specs with opening Chrome browser can be run using the following command:

```sh
$ JS_DRIVER=selenium_chrome rspec spec/system/log_in_spec.rb
```

#### Start the server:

```sh
$ rails server
```

#### Because of the subdomain being enforced, your app will be available on:

```
http://southwark.lvh.me:3000/
or
http://lambeth.lvh.me:3000/
```

## Building production docker

### Create production docker

```sh
docker build -t bops-production -f Dockerfile.production .
```

### Run production docker

```sh
docker run --rm -it -p 3000:3000 -e DATABASE_URL=postgis://postgres@host.docker.internal:5432/bops_development -e RAILS_SERVE_STATIC_FILES=true -e RAILS_ENV=production -e RAILS_LOG_TO_STDOUT=true bops-production:latest bundle exec rails s
```

### Run production docker bash

```sh
docker run --rm -it -e DATABASE_URL=postgis://postgres@host.docker.internal:5432/bops_development -e RAILS_SERVE_STATIC_FILES=true -e RAILS_ENV=production -e RAILS_LOG_TO_STDOUT=true bops-production:latest /bin/bash
```

[1]: https://www.docker.com/products/docker-desktop
[2]: http://localhost:3000/
