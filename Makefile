SHELL := /bin/bash

check-env:
ifndef ENV
	$(error ENV is undefined)
endif

docker-build-server:
	docker build -t climbicus_server server/

docker-build-db:
	docker build -t climbicus_db db/

docker-build: docker-build-server docker-build-db

docker-run: check-env
	docker-compose -f docker-compose.yml -f docker-compose.${ENV}.yml run server $(args)

docker-up: check-env
	docker-compose -f docker-compose.yml -f docker-compose.${ENV}.yml up $(args)

docker-up-build: check-env
	docker-compose -f docker-compose.yml -f docker-compose.${ENV}.yml up --build $(args)

docker-down: check-env
	docker-compose -f docker-compose.yml -f docker-compose.${ENV}.yml down

docker-stop: check-env
	docker-compose -f docker-compose.yml -f docker-compose.${ENV}.yml stop

ec2-deploy: check-env
	rsync -aHv --delete-during --exclude-from rsync_exclude.txt . ec2-climbicus-${ENV}:/home/ec2-user/climbicus/

tests:
	docker exec climbicus_server_1 python -m pytest -v $(args) ./tests

