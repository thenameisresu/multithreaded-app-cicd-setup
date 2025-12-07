# Multi-stage build for Go application
# Stage 1: Build stage
FROM golang:1.25-alpine AS builder

# Set working directory
WORKDIR /app

# Copy go module files
COPY go.mod ./
COPY go.sum* ./

# Download dependencies
RUN go mod download

# Copy source code
COPY . .

# Build the application
# CGO_ENABLED=0: Disable CGO for static binary
# GOOS=linux: Target Linux OS
# -a: Force rebuilding of packages
# -installsuffix cgo: Add suffix to package directory
# -o main: Output binary name
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o main .

# Stage 2: Final minimal image
FROM alpine:latest

# Install ca-certificates for HTTPS requests
RUN apk --no-cache add ca-certificates

# Set working directory
WORKDIR /root/

# Copy binary from builder stage
COPY --from=builder /app/main .

# Expose application port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8080/health || exit 1

# Run the application
CMD ["./main"]