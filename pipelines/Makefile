TARGET ?= mocaccino
PIPELINES ?= test build bump
PIPELINE ?= test
VARS ?=

.PHONY: deploy-all
deploy-all:
	for d in $(PIPELINES); do \
		PIPELINE=$$d $(MAKE) deploy; \
	done

.PHONY: deploy
deploy:
	bash -c "fly -t $(TARGET) set-pipeline -p $(PIPELINE) -l $(VARS) --config  <(gomplate --datasource config=$(PIPELINE).yaml --file templates/$(PIPELINE).gomplate)"
	fly -t $(TARGET) unpause-pipeline -p $(PIPELINE)