#
# A tiny makefile for automating the docker commands needed for this
# repository
#
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
	docker tag archiva:develop $(TAG)

push: tag
	docker push $(TAG)