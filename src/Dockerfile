FROM golang:1.27 AS build

WORKDIR /src

# Copy the module files first so the dependency download is cached
# and only re-runs when go.mod / go.sum change
COPY go.mod go.sum ./
RUN go mod download

# Copy the source code
COPY product-service.go .

# CGO_ENABLED=0 makes a static binary that runs on the minimal image below
RUN CGO_ENABLED=0 GOOS=linux go build -o /product-service product-service.go

# ---- Run stage: tiny image with just the binary ----
FROM gcr.io/distroless/static

COPY --from=build /product-service /product-service

EXPOSE 8081

ENTRYPOINT ["/product-service"]
