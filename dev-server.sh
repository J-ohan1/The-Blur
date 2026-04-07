#!/bin/bash
cd /home/z/my-project
while true; do
  echo "[$(date)] Starting dev server..." >> /home/z/my-project/dev.log
  npx next dev -p 3000 2>&1 | tee -a /home/z/my-project/dev.log
  echo "[$(date)] Server exited, restarting in 2s..." >> /home/z/my-project/dev.log
  sleep 2
done
