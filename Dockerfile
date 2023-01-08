FROM --platform=${BUILDPLATFORM} golang:1-alpine as builder

ARG TARGETOS
ARG TARGETARCH

WORKDIR /opt/app

COPY . .
RUN --mount=type=cache,target=/root/.cache/go-build \
    --mount=type=cache,target=/go/pkg \
    GOOS=${TARGETOS} GOARCH=${TARGETARCH} CGO_ENABLED=0 go build -ldflags '-extldflags "-static"' ./cmd/rollout-operator

RUN apk add --update --no-cache upx && upx --best --lzma rollout-operator

FROM gcr.io/distroless/static:debug
SHELL ["/busybox/sh", "-eo", "pipefail", "-c"]
ENTRYPOINT ["/bin/rollout-operator"]

COPY --from=builder /opt/app/rollout-operator /bin/rollout-operator
RUN addgroup -g 10000 -S rollout-operator && \
    adduser  -u 10000 -S rollout-operator -G rollout-operator
USER rollout-operator:rollout-operator
