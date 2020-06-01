#!/bin/sh

docker network create websites 2> /dev/null

docker-compose up -d --build --remove-orphans
