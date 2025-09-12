DOCKER-RUN = docker compose --profile console run --rm

.DEFAULT_GOAL := up

build:
	docker compose build

up:
	docker compose up || true

down:
	docker compose down

prompt:
	$(DOCKER-RUN) console bash

console:
	$(DOCKER-RUN) console rails console

migrate:
	$(DOCKER-RUN) console rails db:migrate

rollback:
	$(DOCKER-RUN) console rails db:rollback

locales:
	$(DOCKER-RUN) console i18n-tasks normalize

api-docs:
	$(DOCKER-RUN) console rake api:docs:generate submission_api:docs:generate

submission-api-docs: api-docs

submission-api-specs: submissions-specs
	@: # noop: for backwards compatibility with a name that didn't fit the pattern

%-specs:
	$(DOCKER-RUN) console rspec engines/bops_$(@:%-specs=%)/spec

ENGINES := $(wildcard engines/*/spec)
engine-specs: $(patsubst engines/bops_%/spec,%-specs,$(ENGINES))
	@: # noop: so that this doesn't try to run engines/bops_engine/spec

rspec:
	$(DOCKER-RUN) console rspec

cucumber:
	$(DOCKER-RUN) console cucumber

guard:
	$(DOCKER-RUN) console $(BUNDLE-EXEC) guard

db-prompt:
	$(DOCKER-RUN) console psql postgres://postgres:postgres@db

lint:
	$(DOCKER-RUN) console rake rubocop biome herb:lint erb_lint prettier

lint-auto-correct:
	$(DOCKER-RUN) console rake rubocop:fix biome:fix erb_lint:fix prettier:fix

lint-locales:
	$(DOCKER-RUN) console i18n-tasks normalize

# this regenerates the Rubocop TODO and ensures that cops aren't
# turned off over a max number of file offenses. Note: we don't want
# to run this within Docker so we can avoid a write-projected file (by
# the Docker user).
update-rubocop:
	rubocop -A --auto-gen-config --auto-gen-only-exclude --exclude-limit 2000
