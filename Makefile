SHELL := /bin/bash

check-env:
ifndef ENV
	$(error ENV is undefined)
endif

docker-build: check-env
	docker-compose -f docker-compose.yml -f docker-compose.${ENV}.yml build $(args)

# E.g. make args="flask routes" docker-run
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

docker-config: check-env
	docker-compose -f docker-compose.yml -f docker-compose.${ENV}.yml config

docker-logs: check-env
	docker-compose -f docker-compose.yml -f docker-compose.${ENV}.yml logs -f

ec2-deploy: check-env
	rsync -aHv --delete-during --exclude-from rsync_exclude.txt . ec2-climbicus-${ENV}:/home/ec2-user/climbicus/
	rsync ${ENV}_secrets.env ec2-climbicus-${ENV}:/home/ec2-user/climbicus/

tests:
	docker exec climbicus_server_1 python -m pytest -v $(args) ./tests

