# System-design: Cell-Based Architecture POC

A proof of concept demonstrating a multi-cell architecture with isolated databases and caches. Supports both Docker Compose and Kubernetes deployments.

## What is this?

Two independent "cells" that run separately but share a common router. Each cell has its own API, Redis cache, and PostgreSQL database. They're completely isolated - if one cell fails, the other keeps running.

## Architecture Diagram

![Architecture Diagram](docs/TechnicalDiagram.png)

## Choose Your Deployment

### Option 1: Docker Compose (Local Development)

```bash
make start
```

### Option 2: Kubernetes (Kind Cluster)

```bash
make k8s-start
```

## Commands

### Docker Compose

| Command | Description |
|---------|-------------|
| `make start` | Start all services |
| `make clean` | Stop and remove all containers |
| `make test` | Test auto-failover (~40s) |
| `make logs` | View logs |

### Kubernetes

| Command | Description |
|---------|-------------|
| `make k8s-start` | Create cluster, build images, deploy |
| `make k8s-delete` | Delete namespaces |
| `make k8s-test` | Test k8s failover |
| `make k8s-delete-cluster` | Delete kind cluster |

## Endpoints

| Service | Docker Compose | Kubernetes |
|---------|----------------|-------------|
| Router | http://localhost:80 | Port 80 (kind) |
| Cell-1 API | http://localhost:8080 | Via port-forward |
| Cell-2 API | http://localhost:8081 | Via port-forward |
| Prometheus | http://localhost:9090 | Via port-forward |
| Grafana | http://localhost:3000 | Via port-forward |

### Accessing K8s Services

```bash
# Port-forward to services
kubectl port-forward -n cell-1 svc/cell-1-api 8080:8000
kubectl port-forward -n cell-2 svc/cell-2-api 8081:8000
kubectl port-forward -n monitoring svc/grafana 3000:3000
kubectl port-forward -n monitoring svc/prometheus 9090:9090
```

## Key Features

- **Isolated cells** - Separate DB/cache per cell
- **Auto-failover** - Router switches to healthy cell
- **Sticky sessions** - Users stay on same cell
- **Monitoring** - Prometheus + Grafana included

## Project Structure

```
├── code/                    # Shared application code
│   ├── api/
│   ├── worker/
│   ├── router/
│   ├── postgres/
│   ├── monitoring/         # Prometheus & Grafana config
│   └── scripts/
├── docker-compose/          # Docker Compose deployment
├── k8s/                    # Kubernetes manifests
│   ├── kind-config.yaml
│   ├── cell-1/
│   ├── cell-2/
│   └── monitoring/
└── Makefile               # Build targets