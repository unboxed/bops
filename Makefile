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
