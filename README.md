# Cell-Based Architecture POC

A proof of concept demonstrating a multi-cell architecture with isolated databases and caches, using Docker Compose.

## What is this?

Two independent "cells" that run separately but share a common router. Each cell has its own API, Redis cache, and PostgreSQL database. They're completely isolated - if one cell fails, the other keeps running.

## Architecture Diagram

![Architecture Diagram](docs/TechnicalDiagram.png)

## Quick Start

```bash
cd cell-poc
docker-compose up -d
```

## Endpoints

| Service | Port |
|---------|------|
| Router | 80 |
| Cell-1 API | 8080 |
| Cell-2 API | 8081 |
| Prometheus | 9090 |
| Grafana | 3000 |

## Key Features

- **Isolated cells** - Separate DB/cache per cell
- **Auto-failover** - Router switches to healthy cell
- **Sticky sessions** - Users stay on same cell
- **Monitoring** - Prometheus + Grafana included

## Test

```bash
curl localhost:80/health        # via router
curl localhost:8080/health      # cell-1 direct
```



## Documentation

See `plan/plan.md` for full implementation details.