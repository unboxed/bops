DOCKER-RUN = docker-compose run --rm web
DB-RUN = docker-compose run --rm db
BUNDLE-RUN = bundle exec

.DEFAULT_GOAL := up

build:
	docker-compose build

up:
	docker-compose up

prompt:
	$(DOCKER-RUN) bash

db-prompt:
	$(DB-RUN) psql postgres://postgres:postgres@db

lint:
	$(DOCKER-RUN) $(BUNDLE-RUN) rubocop

# this regenerates the Rubocop TODO and ensures that cops aren't
# turned off over a max number of file offenses. Note: we don't want
# to run this within Docker so we can avoid a write-projected file (by
# the Docker user).
update-rubocop:
	rubocop -A --auto-gen-config --auto-gen-only-exclude --exclude-limit 2000
