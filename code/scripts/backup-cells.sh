#!/bin/bash
set -e

echo "Backing up cells..."

CELL1_PG=$(docker ps --filter "name=cell-1-postgres" --format "{{.Names}}")
CELL2_PG=$(docker ps --filter "name=cell-2-postgres" --format "{{.Names}}")

docker exec $CELL1_PG pg_dump -U celluser celldb > cell-1-backup.sql
docker exec $CELL2_PG pg_dump -U celluser celldb > cell-2-backup.sql

echo "Backups created:"
ls -lh *.sql