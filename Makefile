DOCKER-RUN = docker-compose run --rm web
DOCKER-EXEC = docker-compose exec web
DB-RUN = docker-compose run --rm db
BUNDLE-RUN = bundle exec

.DEFAULT_GOAL := up

build:
	git submodule update --init
	docker-compose build

up:
	docker-compose up

prompt:
	$(DOCKER-RUN) bash

aprompt:
	docker-compose run --rm applicants bash

guard:
	$(DOCKER-RUN) $(BUNDLE-RUN) guard

db-prompt:
	$(DB-RUN) psql postgres://postgres:postgres@db

lint:
	$(DOCKER-RUN) $(BUNDLE-RUN) rubocop

e2e:
	$(DOCKER-EXEC) $(BUNDLE-RUN) cucumber features/e2e.feature

# this regenerates the Rubocop TODO and ensures that cops aren't
# turned off over a max number of file offenses. Note: we don't want
# to run this within Docker so we can avoid a write-projected file (by
# the Docker user).
update-rubocop:
	rubocop -A --auto-gen-config --auto-gen-only-exclude --exclude-limit 2000
