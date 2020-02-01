DOCKER := docker
NAMESPACE = gc
IMAGENAME=climbicus
CONTAINER_ID = $(NAMESPACE)_$(IMAGENAME)
VOLUMES = -v $(PWD):/srv/app \
					-v $(PWD)/.jupyter:/root/.jupyter \
					-v $(PWD)/.config:/root/.config

# configure port for Jupyter notebook server
NOTEBOOK_PORT = 8899
TENSORBOARD_PORT = 6006
PORTS = -p $(NOTEBOOK_PORT):$(NOTEBOOK_PORT) -p $(TENSORBOARD_PORT):$(TENSORBOARD_PORT)
ENV_FILE = .env

define task
	$(DOCKER) run --rm --env-file $(ENV_FILE) -i -t $(VOLUMES) $(CONTAINER_ID) $1
endef

check_env:
	@[ -f $(ENV_FILE) ] && \
		echo "$(ENV_FILE) file exists" \
		|| (touch $(ENV_FILE) && echo "$(ENV_FILE) file does not exist - creating empty file")

build:
	$(DOCKER) build --file Dockerfile.local -t $(CONTAINER_ID) .

notebook: build check_env
	$(DOCKER) run --rm --env-file $(ENV_FILE) --name $(CONTAINER_ID) \
								$(PORTS) $(VOLUMES) \
								$(CONTAINER_ID) \
								jupyter notebook --ip=0.0.0.0 --allow-root --no-browser --port=$(NOTEBOOK_PORT) \
								--NotebookApp.custom_display_url=http://localhost:$(NOTEBOOK_PORT)


lab: build check_env
	$(DOCKER) run --rm --env-file $(ENV_FILE) --name $(CONTAINER_ID) \
								$(PORTS) $(VOLUMES) \
								$(CONTAINER_ID) \
								jupyter lab --ip=0.0.0.0 --allow-root --no-browser --port=$(NOTEBOOK_PORT) \
								--NotebookApp.custom_display_url=http://localhost:$(NOTEBOOK_PORT)


sh: build check_env
	@$(call task, /bin/bash)

outdated: build check_env
	@$(call task, pip list -o)
