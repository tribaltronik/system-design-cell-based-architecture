#!/bin/bash
echo "=== Continuous Health Monitoring ==="
echo "Press Ctrl+C to stop"
echo

while true; do
    RESPONSE=$(curl -s http://localhost/health 2>&1)
    if [ $? -eq 0 ]; then
        CELL=$(echo $RESPONSE | grep -o "cell-[12]")
        echo "$(date +%H:%M:%S) - OK $CELL"
    else
        echo "$(date +%H:%M:%S) - FAILED"
    fi
    sleep 1
done