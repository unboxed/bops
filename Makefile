DOCKER-RUN = docker-compose run --rm
DOCKER-E2E = docker-compose -f docker-compose.yml -f docker-compose.e2e.yml

DB-RUN = docker-compose run --rm db
BUNDLE-EXEC = bundle exec

.DEFAULT_GOAL := up

build:
	git submodule update --init
	docker-compose build

up:
	docker-compose up

prompt:
	$(DOCKER-RUN) web bash

aprompt:
	$(DOCKER-RUN) applicants bash

guard:
	$(DOCKER-RUN) web $(BUNDLE-EXEC) guard

db-prompt:
	$(DB-RUN) psql postgres://postgres:postgres@db

lint:
	$(DOCKER-RUN) web $(BUNDLE-EXEC) rubocop

e2e:
	$(DOCKER-E2E) run --rm --service-ports --use-aliases web $(BUNDLE-EXEC) cucumber --profile e2e

# this regenerates the Rubocop TODO and ensures that cops aren't
# turned off over a max number of file offenses. Note: we don't want
# to run this within Docker so we can avoid a write-projected file (by
# the Docker user).
update-rubocop:
	rubocop -A --auto-gen-config --auto-gen-only-exclude --exclude-limit 2000
