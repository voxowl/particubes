#!/bin/sh

docker network create websites 2> /dev/null

docker run --rm \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v "$PWD:$PWD" \
    -w="$PWD" \
    docker/compose:1.24.0 \
    -f docker-compose.yml -f docker-compose-prod.yml \
    up -d --remove-orphans
