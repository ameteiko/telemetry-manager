# Build the manager binary
FROM golang:1.21.0-bullseye as builder

WORKDIR /workspace
# Copy the Go Modules manifests
COPY go.mod go.mod
COPY go.sum go.sum
# cache deps before building and copying source so that we don't need to re-download as much
# and so that source changes don't invalidate our downloaded layer
RUN go mod download

# Copy the go source
COPY main.go main.go
COPY apis/ apis/
COPY controllers/ controllers/
COPY internal/ internal/
COPY webhook/ webhook/

# Clean up unused (test) dependencies and build
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go mod tidy && go build -a -o manager main.go

# Use the fluent-bit image because we need the fluent-bit binary
FROM europe-docker.pkg.dev/kyma-project/prod/tpi/fluent-bit:2.1.8-da21e9f9

WORKDIR /
COPY --from=builder /workspace/manager .

USER 65532:65532

ENTRYPOINT ["/manager"]
