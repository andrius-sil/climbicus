SHELL := /bin/bash

docker-build-server:
		docker build -t climbicus_server server/

docker-build: docker-build-server

docker-run:
		docker-compose up

