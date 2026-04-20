#!/bin/bash
echo "Testing sticky sessions..."

echo "User alice (10 requests):"
for i in {1..10}; do 
    curl -s "http://localhost/health?user_id=alice" | grep -o "cell-[12]"
done

echo ""
echo "User bob (10 requests):"
for i in {1..10}; do 
    curl -s "http://localhost/health?user_id=bob" | grep -o "cell-[12]"
done

echo ""
echo "User charlie (10 requests):"
for i in {1..10}; do 
    curl -s "http://localhost/health?user_id=charlie" | grep -o "cell-[12]"
done