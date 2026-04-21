.PHONY: start build clean test logs k8s-create-cluster k8s-delete-cluster k8s-deploy k8s-delete

build:
	cd docker-compose && docker compose build

start:
	@echo "Starting Cell-Based Architecture..."
	cd docker-compose && docker compose up -d
	@echo ""
	@echo "Services:"
	@echo "  Router:    http://localhost:80"
	@echo "  Cell-1:    http://localhost:8080"
	@echo "  Cell-2:    http://localhost:8081"
	@echo "  Prometheus: http://localhost:9090"
	@echo "  Grafana:    http://localhost:3000 (admin/admin)"

clean:
	cd docker-compose && docker compose down -v

logs:
	cd docker-compose && docker compose logs -f

test:
	@echo "Testing auto-failover..."
	@echo ""
	@echo "Step 1: Both cells up"
	@curl -s --fail http://localhost:8080/health >/dev/null && echo "(Cell-1 OK)"
	@curl -s --fail http://localhost:8081/health >/dev/null && echo "(Cell-2 OK)"
	@echo ""
	@echo "Step 2: Kill Cell-1, check failover"
	-@docker stop $$(docker ps -q --filter "name=docker-compose-cell-1-api") >/dev/null 2>&1
	@echo "    (waiting 35s for nginx failover...)"
	@sleep 35 || true
	@curl -s --fail http://localhost:8081/health >/dev/null 2>&1 && echo "(Cell-2 still works)"
	@curl -s --fail http://localhost:80/health >/dev/null 2>&1 && echo "(Router switched to Cell-2)"
	@echo ""
	@echo "Step 3: Restart Cell-1"
	-@docker start $$(docker ps -aq --filter "name=docker-compose-cell-1-api") >/dev/null 2>&1
	@sleep 3
	@curl -s --fail http://localhost:8080/health >/dev/null 2>&1 && echo "(Cell-1 recovered)"
	@echo ""
	@echo "Done!"

k8s-create-cluster:
	@echo "Creating kind cluster..."
	kind create cluster --config k8s/kind-config.yaml

k8s-delete-cluster:
	@echo "Deleting kind cluster..."
	kind delete cluster --name cell-based-architecture

k8s-deploy:
	@echo "Deploying to k8s..."
	kubectl apply -f k8s/namespace.yaml
	kubectl apply -f k8s/cell-1/
	kubectl apply -f k8s/cell-2/
	kubectl apply -f k8s/router.yaml
	kubectl apply -f k8s/monitoring-rbac.yaml
	kubectl apply -f k8s/monitoring-config.yaml
	kubectl apply -f k8s/monitoring.yaml
	kubectl apply -f k8s/monitoring-dashboards.yaml
	@echo "Waiting for Grafana to be ready..." && sleep 35
	kubectl port-forward -n monitoring svc/grafana 3000:3000 &>/dev/null &
	sleep 3
	curl -s -u admin:admin -X DELETE http://localhost:3000/api/datasources/uid/PBFA97CFB590B2093 || true
	curl -s -u admin:admin -X POST http://localhost:3000/api/datasources -H 'Content-Type: application/json' -d '{"name":"Prometheus","type":"prometheus","url":"http://prometheus.monitoring:9090","access":"proxy","isDefault":true,"uid":"PBFA97CFB590B2093"}'
	cat code/monitoring/grafana/provisioning/dashboards/cell-dashboard.json | python3 -c "import sys,json; d=json.load(sys.stdin); print(json.dumps({'dashboard':d,'overwrite':True}))" | curl -s -u admin:admin -X POST http://localhost:3000/api/dashboards/db -H 'Content-Type: application/json' -d @-
	@echo "Deploy complete!"

k8s-build:
	@echo "Building images for k8s..."
	docker build -t cell-based-architecture-api:latest ./code/api
	docker build -t cell-based-architecture-worker:latest ./code/worker

k8s-load:
	@echo "Loading images into kind..."
	kind load docker-image cell-based-architecture-api:latest --name cell-based-architecture
	kind load docker-image cell-based-architecture-worker:latest --name cell-based-architecture

k8s-delete:
	@echo "Deleting k8s resources..."
	kubectl delete namespace cell-1 cell-2 monitoring
	kubectl delete -f k8s/router.yaml

k8s-test:
	@echo "Testing k8s failover..."
	@echo ""
	@echo "Step 1: Both cells up"
	@echo "    Checking cell-1..."
	@kubectl exec deploy/cell-1-api -n cell-1 -- python3 -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')" >/dev/null 2>&1 && echo "    (Cell-1 OK)" || echo "    (Cell-1 FAILED)"
	@echo "    Checking cell-2..."
	@kubectl exec deploy/cell-2-api -n cell-2 -- python3 -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')" >/dev/null 2>&1 && echo "    (Cell-2 OK)" || echo "    (Cell-2 FAILED)"
	@echo ""
	@echo "Step 2: Delete Cell-1 API pod (forcing restart)"
	@kubectl delete pod -n cell-1 -l app=cell-1-api
	@echo "    (waiting 30s for k8s to restart pod...)"
	@sleep 30
	@kubectl exec deploy/cell-1-api -n cell-1 -- python3 -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')" >/dev/null 2>&1 && echo "    (Cell-1 recovered)" || echo "    (Cell-1 starting...)"
	@kubectl exec deploy/cell-2-api -n cell-2 -- python3 -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')" >/dev/null 2>&1 && echo "    (Cell-2 still works)"
	@echo ""
	@echo "Step 3: Delete Cell-2 API pod"
	@kubectl delete pod -n cell-2 -l app=cell-2-api
	@sleep 30
	@kubectl exec deploy/cell-2-api -n cell-2 -- python3 -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')" >/dev/null 2>&1 && echo "    (Cell-2 recovered)" || echo "    (Cell-2 starting...)"
	@echo ""
	@echo "Done!"

k8s-logs:
	@echo "Streaming logs from all pods..."
	kubectl logs -l app=cell-1-api -n cell-1 --tail=10 -f &
	kubectl logs -l app=cell-2-api -n cell-2 --tail=10 -f