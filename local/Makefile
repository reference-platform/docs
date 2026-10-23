include versions.env

.PHONY: help preflight up demo load test down clean

help:
	@echo "Targets: preflight up down clean"

preflight:
	@./preflight.sh

up:
	@./bootstrap/cluster.sh

demo:
	@echo "not implemented yet"

load:
	@echo "not implemented yet"

test:
	@echo "not implemented yet"

down:
	@kind delete cluster --name $(CLUSTER_NAME)
	@docker stop zot-cache >/dev/null 2>&1 || true

clean: down
	@docker rm -f zot-cache >/dev/null 2>&1 || true
	@docker volume rm zot-cache-data >/dev/null 2>&1 || true
