FROM 567716553783.dkr.ecr.us-east-1.amazonaws.com/golang-builder:1.9.6-go1.18.3 as builder

ARG VERSION=dev

WORKDIR /app
COPY . .
RUN go mod vendor
RUN go build -o main -ldflags=-X=main.version=${VERSION} main.go 

FROM debian:buster-slim
COPY --from=builder /app/main /go/bin/main
ENV PATH="/go/bin:${PATH}"
CMD ["main"]