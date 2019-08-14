#!/bin/bash

GOPATH="$PWD"/go go run "$PWD"/go/src/mailer/*.go "$@"