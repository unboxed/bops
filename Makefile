DOCKER-RUN = docker compose --profile console run --rm

.DEFAULT_GOAL := up

build:
	git submodule update --init
	docker compose build

up:
	docker compose up || true

down:
	docker compose down

prompt:
	$(DOCKER-RUN) console bash

aprompt:
	$(DOCKER-RUN) aconsole bash

console:
	$(DOCKER-RUN) console rails console

aconsole:
	$(DOCKER-RUN) aconsole rails console

migrate:
	$(DOCKER-RUN) console rails db:migrate

rollback:
	$(DOCKER-RUN) console rails db:rollback

locales:
	$(DOCKER-RUN) console i18n-tasks normalize

api-docs:
	$(DOCKER-RUN) console rake api:docs:generate

api-specs:
	$(DOCKER-RUN) console rspec engines/bops_api/spec

rspec:
	$(DOCKER-RUN) console rspec

cucumber:
	$(DOCKER-RUN) console cucumber

guard:
	$(DOCKER-RUN) console $(BUNDLE-EXEC) guard

db-prompt:
	$(DOCKER-RUN) console psql postgres://postgres:postgres@db

lint:
	$(DOCKER-RUN) console rubocop

lint-auto-correct:
	$(DOCKER-RUN) console rubocop --auto-correct-all

# this regenerates the Rubocop TODO and ensures that cops aren't
# turned off over a max number of file offenses. Note: we don't want
# to run this within Docker so we can avoid a write-projected file (by
# the Docker user).
update-rubocop:
	rubocop -A --auto-gen-config --auto-gen-only-exclude --exclude-limit 2000
