FROM golang:1.19.3-alpine3.16

ENV GOPATH=/go

RUN go install golang.org/x/tools/cmd/godoc@v0.2.0

COPY /entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
