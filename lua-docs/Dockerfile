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

