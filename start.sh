#!/bin/bash

cd "$(dirname "$0")"

if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
fi

cd /home/ubuntu/afe_chat/api
/home/ubuntu/.local/bin/uv run uvicorn main:app --workers 1 --host "0.0.0.0" --port 8080 > logfile 2>&1
