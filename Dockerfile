ARG GO_VERSION=1.27.1
ARG GO_IMAGE_DIGEST=sha256:cf6fca6641884b8433441b2b0652976f975e1d0fdd26d177eaaf8596087f3125
ARG CADDY_VERSION=2.11.4
ARG CADDY_IMAGE_DIGEST=sha256:5f5c8640aae01df9654968d946d8f1a56c497f1dd5c5cda4cf95ab7c14d58648

FROM golang:${GO_VERSION}-alpine3.24@${GO_IMAGE_DIGEST} AS builder

ARG CADDY_VERSION
ARG XCADDY_VERSION=0.4.7
ARG CLOUDFLARE_VERSION=0.2.4

RUN apk add --no-cache ca-certificates git \
    && go install github.com/caddyserver/xcaddy/cmd/xcaddy@v${XCADDY_VERSION} \
    && xcaddy build v${CADDY_VERSION} \
        --with github.com/caddy-dns/cloudflare@v${CLOUDFLARE_VERSION} \
        --output /usr/bin/caddy

FROM builder AS vulncheck

ARG GOVULNCHECK_VERSION=1.7.0
RUN go install golang.org/x/vuln/cmd/govulncheck@v${GOVULNCHECK_VERSION}
ENTRYPOINT ["govulncheck"]
CMD ["-mode=binary", "/usr/bin/caddy"]

FROM caddy:${CADDY_VERSION}-alpine@${CADDY_IMAGE_DIGEST}

RUN addgroup -S -g 1000 caddy \
    && adduser -S -D -H -u 1000 -G caddy caddy \
    && chown -R caddy:caddy /config /data

COPY --from=builder /usr/bin/caddy /usr/bin/caddy

USER 1000:1000
EXPOSE 8080 8443
