container_name := elastalert
container_registry := quay.io/nordstrom
elastalert_version := 0.0.95
container_release := $(elastalert_version)

.PHONY: build/image tag/image push/image

build/image:
	docker build \
		--build-arg ELASTALERT_VERSION=$(elastalert_version) \
		-t $(container_name) .

tag/image: build/image
	docker tag $(container_name) $(container_registry)/$(container_name):$(container_release)

push/image: tag/image
	docker push $(container_registry)/$(container_name):$(container_release)