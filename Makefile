DOCKER_IMAGE ?= klakegg/hugo:0.78.2
DEPLOY_MSG ?= Rebuilding site $$(date +'%F %T %Z')

HUGO = \
	docker run --rm -it \
	-u $$(id -u):$$(id -g) \
	--group-add $$($(DOCKER_GROUP_COMMAND)) \
	-v $$(pwd):/src \
	$(PORT_FORWARD) \
	$(DOCKER_IMAGE)
DOCKER_GROUP_COMMAND = \
	docker run --rm -i \
	-v /run/docker.sock:/run/docker.sock \
	--entrypoint ls $(DOCKER_IMAGE) -l /run/docker.sock \
	| awk '{print $$4}'

.PHONY: drafts
drafts: PORT_FORWARD = -p 1313:1313
drafts:
	$(HUGO) server -D

.PHONY: live
live: PORT_FORWARD = -p 1313:1313
live:
	$(HUGO) server

.PHONY: build
build:
	$(HUGO)

# Based on https://gohugo.io/hosting-and-deployment/hosting-on-github/#put-it-into-a-script
.PHONY: publish
publish: build
	# Push submodule, then update root's submodule reference.
	cd public && \
	git add . && \
	git commit -m "$(DEPLOY_MSG)" && \
	git push origin master && \
	cd .. && \
	git add public/ && \
	git commit -m "$(DEPLOY_MSG)" && \
	git push origin master

.PHONY: new-post
new-post:
	$(HUGO) new $(filename)
