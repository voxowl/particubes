#!/bin/sh

docker network create websites 2> /dev/null

docker-compose -f docker-compose.yml -f docker-compose-prod.yml up -d --build --remove-orphans