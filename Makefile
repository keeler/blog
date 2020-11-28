DOCKER_IMAGE = klakegg/hugo:0.78.2
DOCKER_GROUP_COMMAND = \
	docker run --rm -i \
	-v /run/docker.sock:/run/docker.sock \
	--entrypoint ls $(DOCKER_IMAGE) -l /run/docker.sock \
	| awk '{print $$4}'

HUGO = \
	docker run --rm -it \
	-u $$(id -u):$$(id -g) \
	--group-add $$($(DOCKER_GROUP_COMMAND)) \
	-v $$(pwd):/src \
	-p 1313:1313 \
	$(DOCKER_IMAGE)

DEPLOY_MSG ?= Rebuilding site $$(date)


.PHONY: run
run:
	$(HUGO) server -D

.PHONY: run.prepublish
run.prepublish:
	$(HUGO) server

.PHONY: build
build:
	$(HUGO)

# Based on https://gohugo.io/hosting-and-deployment/hosting-on-github/#put-it-into-a-script
.PHONY: publish
publish: build
	cd public && \
	git add . && \
	git commit -m "$(DEPLOY_MSG)" && \
	git push origin master