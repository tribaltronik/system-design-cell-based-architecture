.PHONY: start clean test

start:
	@echo "Starting Cell-Based Architecture POC..."
	docker-compose up -d
	@echo ""
	@echo "Services:"
	@echo "  Router:    http://localhost:80"
	@echo "  Cell-1:    http://localhost:8080"
	@echo "  Cell-2:    http://localhost:8081"
	@echo "  Prometheus: http://localhost:9090"
	@echo "  Grafana:    http://localhost:3000 (admin/admin)"

clean:
	docker-compose down -v

test:
	@echo "Testing auto-failover..."
	@echo ""
	@echo "Step 1: Both cells up"
	@curl -s --fail http://localhost:8080/health >/dev/null && echo "(Cell-1 OK)"
	@curl -s --fail http://localhost:8081/health >/dev/null && echo "(Cell-2 OK)"
	@echo ""
	@echo "Step 2: Kill Cell-1, check failover"
	-@docker stop $$(docker ps -q --filter "name=cell-1-api") >/dev/null 2>&1
	@echo "    (waiting 35s for nginx failover...)"
	@sleep 35 || true
	@curl -s --fail http://localhost:8081/health >/dev/null 2>&1 && echo "(Cell-2 still works)"
	@curl -s --fail http://localhost:80/health >/dev/null 2>&1 && echo "(Router switched to Cell-2)"
	@echo ""
	@echo "Step 3: Restart Cell-1"
	-@docker start $$(docker ps -aq --filter "name=cell-1-api") >/dev/null 2>&1
	@sleep 3
	@curl -s --fail http://localhost:8080/health >/dev/null 2>&1 && echo "(Cell-1 recovered)"
	@echo ""
	@echo "Done!"