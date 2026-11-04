include versions.env
export

KUBECTL = kubectl --context kind-$(CLUSTER_NAME)

.PHONY: help preflight up status forward demo load test down clean

help:
	@echo "Targets: preflight up status forward down clean"

preflight:
	@./preflight.sh

up:
	@./bootstrap/cluster.sh
	@./bootstrap/argocd.sh
	@./bootstrap/wait.sh

status:
	@$(KUBECTL) get nodes
	@echo
	@$(KUBECTL) -n argocd get applications
	@echo
	@$(KUBECTL) -n apps get pods,job

forward:
	@echo "web:    http://localhost:8081"
	@echo "argocd: https://localhost:8080"
	@trap 'kill $$(jobs -p)' EXIT; \
	$(KUBECTL) -n apps port-forward svc/sample-app-web 8081:8080 & \
	$(KUBECTL) -n argocd port-forward svc/argocd-server 8080:443 & \
	wait

demo:
	@echo "not implemented yet"

load:
	@echo "not implemented yet"

test:
	@echo "not implemented yet"

down:
	@kind delete cluster --name $(CLUSTER_NAME)
	@docker stop $(CACHE_NAME) >/dev/null 2>&1 || true

clean: down
	@docker rm -f $(CACHE_NAME) >/dev/null 2>&1 || true
	@docker volume rm $(CACHE_VOLUME) >/dev/null 2>&1 || true
