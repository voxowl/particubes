# particubes.com

FROM golang:1.12.6-alpine3.10

# -----------------------
# INSTALL GIT (for `go get`)
# -----------------------

# RUN apk update
# RUN apk add git

# -----------------------
# INSTALL WEB SERVER
# -----------------------

COPY go /go
WORKDIR /go/src/mailer
# RUN go install

# -----------------------
# START WEB SERVER
# -----------------------

ENTRYPOINT ["ash"]



