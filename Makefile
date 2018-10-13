#
# A tiny makefile for automating the docker commands needed for this
# repository
#
TAG ?= latest
REPOSITORY_NAME = xetusoss/archiva
REGISTRY ?= ""
PUSH_TAG = $(REPOSITORY_NAME):$(TAG)
ifneq ("$(REGISTRY)", "")
	PUSH_TAG = $(REGISTRY)/$(REPOSITORY_NAME):$(TAG)
endif
export TAG

showvars:
	@echo TAG = ${TAG}
	@echo REPOSITORY_NAME = ${REPOSITORY_NAME}
	@echo REGISTRY = ${REGISTRY}
	@echo PUSH_PATH = ${PUSH_PATH}

clean:
	-rm -rv ./logs
	docker-compose -f docker-compose.yaml\
		down --volumes --remove-orphans
	docker-compose -f docker-compose.yaml\
		-f docker-compose.mysql.yaml\
		down --volumes --remove-orphans
	docker-compose -f docker-compose.yaml\
		-f docker-compose.nginx-https.yaml\
		down --volumes --remove-orphans

build:
	docker-compose -f docker-compose.yaml build

test: build
	./local-tests.sh

tag:
	if [ "$(REGISTRY)" != "" ]; then\
		docker tag $(REPOSITORY_NAME):$(TAG) $(PUSH_TAG);\
	fi;

push: tag
	docker push $(PUSH_TAG)
