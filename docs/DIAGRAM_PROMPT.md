# Diagram Generation Prompt

Use this prompt with an image generation AI (like DALL-E, Midjourney, etc.) to create the architecture diagram.

> Note: The working diagram is saved as `docs/TechnicalDiagram.png`

---

## Prompt

Create a clean technical diagram showing a Cell-Based Architecture POC using Docker containers.

### Layout: Top-down hierarchical structure

**LAYER 1 - ROUTER (Top Center)**
- Label: "Nginx Router (Port 80)"
- Subtitle: "Load balancer with failover & sticky sessions"
- Shows load balancing arrows to two cells
- Use round-robin distribution with max_fails=3 fail_timeout=30s

**LAYER 2 - TWO ISOLATED CELLS (Left and Right sides)**

**LEFT CELL (Cell-1):**
- Label: "Cell-1" (highlighted in blue #3B82F6)
- Subtitle: "Isolated network: cell-1-net"
- Components shown as stacked boxes:
  * "FastAPI (Port 8080)" - "Python 3.11 + FastAPI"
  * "Redis Cache" - "Redis 7 - 6379"
  * "PostgreSQL" - "PostgreSQL 15 - 5432"
- Connection lines between: API → Redis → PostgreSQL
- Data flow arrows labeled with cache strategy (5min TTL)

**RIGHT CELL (Cell-2):**
- Label: "Cell-2" (highlighted in green #10B981)  
- Subtitle: "Isolated network: cell-2-net"
- Components shown as stacked boxes:
  * "FastAPI (Port 8081)" - "Python 3.11 + FastAPI"
  * "Redis Cache" - "Redis 7 - 6379"
  * "PostgreSQL" - "PostgreSQL 15 - 5432"
- Connection lines between: API → Redis → PostgreSQL

**LAYER 3 - MONITORING (Bottom):**
- Label: "Monitoring Stack"
- Shows: 
  * "Prometheus (9090)" - "Scrapes metrics from both cells"
  * "Grafana (3000)" - "dashboards (admin/admin)"
- Dotted line connections from both cells to Prometheus

### Data Flow Paths:
- Router → Cell-1 / Cell-2 (round-robin)
- API → Redis (cache check) → PostgreSQL (fallback to DB)
- Write operations invalidate cache

### Failover Scenario:
- Draw curved dashed arrow showing traffic rerouting when one cell fails
- Label: "Automatic failover (~30s)"

### Style:
- Modern technical diagram, white/light gray background (#F8FAFC)
- Use distinct colors for each cell (blue #3B82F6 vs green #10B981)
- Dashed rectangles for network boundaries
- Solid arrows for data flow, dashed for failover
- Clean sans-serif fonts (Inter or Roboto)
- Include Docker whale icons where appropriate
- Use consistent box rounded corners

### Caption: 
"Cell-Based Architecture POC - Two isolated production cells with shared routing layer and monitoring"

### Subtitle: 
"Tech Stack: Python 3.11 • FastAPI • Redis 7 • PostgreSQL 15 • Nginx • Docker Compose"

---

## Alternative: Use Excalidraw

Load the excalidraw-diagram skill and create the diagram programmatically using JSON format.

```bash
# Load skill then create diagram
```