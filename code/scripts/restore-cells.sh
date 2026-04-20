#!/bin/bash
set -e

echo "Restoring cells from backup..."

CELL1_PG=$(docker ps --filter "name=cell-1-postgres" --format "{{.Names}}")
CELL2_PG=$(docker ps --filter "name=cell-2-postgres" --format "{{.Names}}")

echo "Restoring Cell-1..."
docker exec -i $CELL1_PG psql -U celluser celldb -c "DROP TABLE IF EXISTS data;" >/dev/null 2>&1 || true
cat cell-1-backup.sql | docker exec -i $CELL1_PG psql -U celluser celldb

echo "Restoring Cell-2..."
docker exec -i $CELL2_PG psql -U celluser celldb -c "DROP TABLE IF EXISTS data;" >/dev/null 2>&1 || true
cat cell-2-backup.sql | docker exec -i $CELL2_PG psql -U celluser celldb

echo "Restore complete"