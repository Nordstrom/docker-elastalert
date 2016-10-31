image_name := elastalert
image_registry := quay.io/nordstrom
elastalert_version := 0.1.3
image_release := $(elastalert_version)

build_args := --build-arg ELASTALERT_VERSION=$(elastalert_version)

ifdef http_proxy
build_args += --build-arg http_proxy=$(http_proxy)
build_args += --build-arg https_proxy=$(https_proxy)
endif

.PHONY: build/image tag/image push/image

build/image:
	docker build -t $(image_name) $(build_args) .

tag/image: build/image
	docker tag $(image_name) $(image_registry)/$(image_name):$(image_release)

push/image: tag/image
	docker push $(image_registry)/$(image_name):$(image_release)
