#!/bin/bash
while true; do
  bun run dev > dev.log 2>&1 &
  DEV_PID=$!
  
  # Wait for server to be ready
  for i in $(seq 1 30); do
    if curl -s -o /dev/null -w "" http://localhost:3000 2>/dev/null; then
      break
    fi
    sleep 1
  done
  
  # Keep pinging to stay alive
  while kill -0 $DEV_PID 2>/dev/null; do
    curl -s -o /dev/null -w "" http://localhost:3000 2>/dev/null
    sleep 5
  done
  
  echo "Server died, restarting..." >> dev.log
  sleep 2
done
