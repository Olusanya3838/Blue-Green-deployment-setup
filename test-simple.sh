#!/bin/bash

# Simple Blue/Green Failover Test Script
# Tests the basic functionality step by step

set -e

echo "================================"
echo "Blue/Green Failover Test"
echo "================================"
echo ""

# Test 1: Check if services are running
echo "TEST 1: Checking if services are running..."
echo "-------------------------------------------"

echo -n "  Nginx (port 8080): "
if curl -sf http://localhost:8080/version > /dev/null 2>&1; then
    echo "✓ OK"
else
    echo "✗ FAILED - Is docker-compose running?"
    exit 1
fi

echo -n "  Blue (port 8081): "
if curl -sf http://localhost:8081/healthz > /dev/null 2>&1; then
    echo "✓ OK"
else
    echo "✗ FAILED"
    exit 1
fi

echo -n "  Green (port 8082): "
if curl -sf http://localhost:8082/healthz > /dev/null 2>&1; then
    echo "✓ OK"
else
    echo "✗ FAILED"
    exit 1
fi

echo ""

# Test 2: Verify traffic goes to Blue initially
echo "TEST 2: Verifying initial routing (should be Blue)..."
echo "-------------------------------------------------------"

for i in {1..5}; do
    response=$(curl -s -I http://localhost:8080/version)
    pool=$(echo "$response" | grep -i "X-App-Pool:" | awk '{print $2}' | tr -d '\r\n')
    status=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/version)
    
    if [ "$status" = "200" ]; then
        echo "  Request $i: Status $status, Pool: $pool"
    else
        echo "  Request $i: Status $status - FAILED"
        exit 1
    fi
    
    sleep 0.5
done

echo ""

# Test 3: Trigger chaos on Blue
echo "TEST 3: Triggering chaos mode on Blue..."
echo "-----------------------------------------"

chaos_status=$(curl -s -o /dev/null -w "%{http_code}" -X POST "http://localhost:8081/chaos/start?mode=error")

if [ "$chaos_status" = "200" ]; then
    echo "  ✓ Chaos mode activated on Blue (will return 500 errors)"
else
    echo "  ✗ Failed to activate chaos mode"
    exit 1
fi

echo "  Waiting 2 seconds for failover to activate..."
sleep 2
echo ""

# Test 4: Verify traffic switches to Green
echo "TEST 4: Verifying failover to Green..."
echo "---------------------------------------"

green_count=0
error_count=0

for i in {1..10}; do
    response=$(curl -s -I http://localhost:8080/version)
    pool=$(echo "$response" | grep -i "X-App-Pool:" | awk '{print $2}' | tr -d '\r\n')
    status=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/version)
    
    if [ "$status" = "200" ]; then
        echo "  Request $i: Status $status, Pool: $pool"
        if [ "$pool" = "green" ]; then
            green_count=$((green_count + 1))
        fi
    else
        echo "  Request $i: Status $status - ERROR"
        error_count=$((error_count + 1))
    fi
    
    sleep 0.5
done

echo ""

# Test 5: Evaluate results
echo "TEST 5: Evaluating results..."
echo "-----------------------------"

echo "  Total requests: 10"
echo "  Green responses: $green_count"
echo "  Failed requests: $error_count"

success=true

if [ $error_count -eq 0 ]; then
    echo "  ✓ PASS: Zero failed requests"
else
    echo "  ✗ FAIL: Found $error_count failed requests"
    success=false
fi

green_percentage=$((green_count * 100 / 10))
if [ $green_percentage -ge 95 ]; then
    echo "  ✓ PASS: ${green_percentage}% traffic routed to Green (≥95%)"
else
    echo "  ✗ FAIL: Only ${green_percentage}% traffic routed to Green (<95%)"
    success=false
fi

if [ $green_count -gt 0 ]; then
    echo "  ✓ PASS: Failover to Green detected"
else
    echo "  ✗ FAIL: No failover detected"
    success=false
fi

echo ""

# Cleanup: Stop chaos mode
echo "CLEANUP: Stopping chaos mode on Blue..."
curl -s -X POST http://localhost:8081/chaos/stop > /dev/null 2>&1
echo "  ✓ Chaos mode stopped"

echo ""
echo "================================"
if [ "$success" = true ]; then
    echo "ALL TESTS PASSED ✓"
    echo "================================"
    exit 0
else
    echo "TESTS FAILED ✗"
    echo "================================"
    exit 1
fi

