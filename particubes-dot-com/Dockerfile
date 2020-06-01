# particubes.com

FROM golang:1.14.3-alpine

# -----------------------
# INSTALL GIT (for `go get`)
# -----------------------

RUN apk update
RUN apk add git

# -----------------------
# INSTALL WEB SERVER
# -----------------------

COPY go /go
WORKDIR /go/src/website
RUN go install

# -----------------------
# COPY CONTENT
# -----------------------

COPY content /www

# ---------------------
# EXPOSE ports
# ---------------------

EXPOSE 80

# -----------------------
# START WEB SERVER
# -----------------------

CMD ["website"]

