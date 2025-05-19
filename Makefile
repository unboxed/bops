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
	$(DOCKER-RUN) console rake api:docs:generate

submission-api-docs:
	$(DOCKER-RUN) console rake submission_api:docs:generate

api-specs:
	$(DOCKER-RUN) console rspec engines/bops_api/spec

submission-api-specs:
	$(DOCKER-RUN) console rspec engines/bops_submissions/spec

admin-specs:
	$(DOCKER-RUN) console rspec engines/bops_admin/spec

config-specs:
	$(DOCKER-RUN) console rspec engines/bops_config/spec

core-specs:
	$(DOCKER-RUN) console rspec engines/bops_core/spec

uploads-specs:
	$(DOCKER-RUN) console rspec engines/bops_uploads/spec

engine-specs: api-specs admin-specs config-specs core-specs uploads-specs

rspec:
	$(DOCKER-RUN) console rspec

cucumber:
	$(DOCKER-RUN) console cucumber

guard:
	$(DOCKER-RUN) console $(BUNDLE-EXEC) guard

db-prompt:
	$(DOCKER-RUN) console psql postgres://postgres:postgres@db

lint:
	$(DOCKER-RUN) console rake rubocop biome erblint

lint-auto-correct:
	$(DOCKER-RUN) console rake rubocop:fix biome:fix erblint:fix

lint-locales:
	$(DOCKER-RUN) console i18n-tasks normalize

# this regenerates the Rubocop TODO and ensures that cops aren't
# turned off over a max number of file offenses. Note: we don't want
# to run this within Docker so we can avoid a write-projected file (by
# the Docker user).
update-rubocop:
	rubocop -A --auto-gen-config --auto-gen-only-exclude --exclude-limit 2000
