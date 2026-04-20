#!/bin/bash
set -e

echo "=== Testing Cell Isolation ==="
echo

echo "1. Writing different data to same key in each cell..."
curl -s -X POST http://localhost:8080/data -H "Content-Type: application/json" -d '{"key":"shared","value":"cell-1-data"}'
echo ""
curl -s -X POST http://localhost:8081/data -H "Content-Type: application/json" -d '{"key":"shared","value":"cell-2-data"}'
echo ""

echo "2. Reading from each cell..."
echo "Cell-1 response:"
curl -s http://localhost:8080/data/shared
echo ""
echo "Cell-2 response:"
curl -s http://localhost:8081/data/shared
echo ""

echo "3. Killing cell-1..."
CELL1_CONTAINER=$(docker ps --filter "name=docker-compose-cell-1-api" --format "{{.Names}}")
docker stop $CELL1_CONTAINER
echo ""

echo "4. Testing cell-2 (should still work)..."
curl -s http://localhost:8081/health
echo ""

echo "5. Restarting cell-1..."
docker start $CELL1_CONTAINER
sleep 10
echo ""

echo "6. Testing cell-1 (should be recovered)..."
curl -s http://localhost:8080/health
echo ""

echo "=== Isolation test complete ==="