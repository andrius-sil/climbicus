SHELL := /bin/bash

docker-build-server:
		docker build -t climbicus_server server/

docker-build-db:
		docker build -t climbicus_db db/

docker-build: docker-build-server docker-build-db

docker-run:
		docker-compose -f docker-compose.yml -f docker-compose.dev.yml up

docker-run-prod:
		docker-compose -f docker-compose.yml up

ec2-deploy:
	rsync -aHv --delete-during --exclude-from rsync_exclude.txt . ec2-climbicus-dev:/home/ec2-user/climbicus/

