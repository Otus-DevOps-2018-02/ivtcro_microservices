include vars

default: build push

build: build_reddit build_monitoring build_logging

build_reddit: build_comment build_ui build_post

build_comment:
	@echo $(delimeter) \"$@\" "target started: " $(delimeter)
	@cd src/comment && \
	./docker_build.sh
	@echo $(delimeter) \"$@\" "END" $(delimeter)

build_ui:
	@echo $(delimeter) \"$@\" "target started: " $(delimeter)
	@cd src/ui && \
	./docker_build.sh
	@echo $(delimeter) \"$@\" "END" $(delimeter)

build_post:
	@echo $(delimeter) \"$@\" "target started: " $(delimeter)
	@cd src/post-py && \
	./docker_build.sh
	@echo $(delimeter) \"$@\" "END" $(delimeter)

build_monitoring: build_prometheus build_mongo_exporter build_alertmanager build_grafana

build_prometheus:
	@echo $(delimeter) \"$@\" "target started: " $(delimeter)
	@cd monitoring/prometheus && \
	docker build -t $(USER_NAME)/prometheus .
	@echo $(delimeter) \"$@\" "END" $(delimeter)

build_mongo_exporter:
	@echo $(delimeter) \"$@\" "target started: " $(delimeter)
	@cd monitoring/mongodb_exporter && \
	docker build -t $(USER_NAME)/mongodb_exporter .
	@echo $(delimeter) \"$@\" "END" $(delimeter)

build_alertmanager:
	@echo $(delimeter) \"$@\" "target started: " $(delimeter)
	@cd monitoring/alertmanager && \
	docker build -t $(USER_NAME)/alertmanager .
	@echo $(delimeter) \"$@\" "END" $(delimeter)

build_grafana:
	@echo $(delimeter) \"$@\" "target started: " $(delimeter)
	@cd monitoring/grafana && \
	docker build -t $(USER_NAME)/grafana .
	@echo $(delimeter) \"$@\" "END" $(delimeter)

build_monitoring: build_fluentd

build_fluentd:
	@echo $(delimeter) \"$@\" "target started: " $(delimeter)
	@cd logging/fluentd && \
	docker build -t $(USER_NAME)/fluentd .
	@echo $(delimeter) \"$@\" "END" $(delimeter)

push:
	@echo $(delimeter) \"$@\" "target started: " $(delimeter)
	@docker login --username $(USER_NAME) --password-stdin < ./docker_pwd
	@docker push $(USER_NAME)/ui:$(APP_IMAGE_TAG)
	@docker push $(USER_NAME)/comment:$(APP_IMAGE_TAG)
	@docker push $(USER_NAME)/post:$(APP_IMAGE_TAG)
	@docker push $(USER_NAME)/prometheus
	@docker push $(USER_NAME)/mongodb_exporter
	@docker push $(USER_NAME)/alertmanager
	@docker push $(USER_NAME)/grafana
	@echo $(delimeter) \"$@\" "END" $(delimeter)
