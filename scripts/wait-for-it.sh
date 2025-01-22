#!/bin/bash
set -e

HOST=$1
PORT=$2
TIMEOUT=${3:-30}

echo "Waiting for $HOST:$PORT to be ready..."

for i in $(seq $TIMEOUT); do
  nc -z $HOST $PORT && echo "$HOST:$PORT is ready!" && exit 0
  sleep 1
done

echo "Timeout reached! $HOST:$PORT is not ready."
exit 1
