FROM golang:1.21-alpine AS builder

# Install dependencies
RUN apk add --no-cache git build-base leveldb-dev geos-dev proj-dev

# Clone and build imposm3
RUN git clone https://github.com/omniscale/imposm3.git /imposm3
WORKDIR /imposm3
RUN make build

# Final stage
FROM alpine:latest

# Install runtime dependencies
RUN apk add --no-cache leveldb geos proj

# Copy binary from builder
COPY --from=builder /imposm3/imposm /usr/local/bin/imposm

# Create working directory
WORKDIR /data

ENTRYPOINT ["imposm"]
