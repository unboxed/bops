DOCKER-RUN = docker compose run --rm

.DEFAULT_GOAL := up

build:
	git submodule update --init
	docker compose build

up:
	docker compose up

down:
	docker compose down

prompt:
	$(DOCKER-RUN) web bash

aprompt:
	$(DOCKER-RUN) applicants bash

console:
	$(DOCKER-RUN) web rails console

migrate:
	$(DOCKER-RUN) web rails db:migrate

rollback:
	$(DOCKER-RUN) web rails db:rollback

rspec:
	$(DOCKER-RUN) web rspec

cucumber:
	$(DOCKER-RUN) web cucumber

guard:
	$(DOCKER-RUN) web $(BUNDLE-EXEC) guard

db-prompt:
	$(DOCKER-RUN) web psql postgres://postgres:postgres@db

lint:
	$(DOCKER-RUN) web rubocop

lint-auto-correct:
	$(DOCKER-RUN) web rubocop --auto-correct-all

# this regenerates the Rubocop TODO and ensures that cops aren't
# turned off over a max number of file offenses. Note: we don't want
# to run this within Docker so we can avoid a write-projected file (by
# the Docker user).
update-rubocop:
	rubocop -A --auto-gen-config --auto-gen-only-exclude --exclude-limit 2000
