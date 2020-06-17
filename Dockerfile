FROM golang:1.14-stretch as base

WORKDIR /go/src/github.com/alexeldeib/go-srv

COPY go.mod .
COPY go.sum .
COPY server.go .

RUN go build -ldflags '-extldflags "-fno-PIC -static"' -buildmode pie -tags 'osusergo netgo static_build' -o /bin/server .

FROM gcr.io/distroless/static:nonroot
COPY --from=base /bin/server /bin/server

ENTRYPOINT ["/bin/server"]
