FROM golang:1.19.2

ENV GOPATH /
RUN go install golang.org/x/tools/cmd/godoc@v0.2.0
COPY /entrypoint.sh /entrypoint.sh
CMD ["/entrypoint.sh"]
