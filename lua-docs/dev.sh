#!/bin/sh

docker run --rm -ti \
-v $(pwd)/go:/go \
-v $(pwd)/content:/www \
-p 80:80 \
-w="/go/src/website" \
golang:1.12.6-alpine3.10 ash
