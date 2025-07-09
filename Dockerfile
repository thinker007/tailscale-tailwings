ARG TSVERSION=1.84.0
ARG TSFILE=tailscale_${TSVERSION}_amd64.tgz
ARG HEADSCALE_VERSION=0.26.1 # See above URL for latest version, e.g. "X.Y.Z" (NOTE: do not add the "v" prefix!)
ARG HEADSCALE_ARCH=amd64 # Your system architecture, e.g. "amd64"
FROM alpine:latest as build
ARG TSFILE
ARG HEADSCALE_VERSION
ARG HEADSCALE_ARCH
WORKDIR /app

RUN wget https://pkgs.tailscale.com/stable/${TSFILE} && \
  tar xzf ${TSFILE} --strip-components=1
RUN wget --output-document=/app/headscale https://github.com/juanfont/headscale/releases/download/v${HEADSCALE_VERSION}/headscale_${HEADSCALE_VERSION}_linux_${HEADSCALE_ARCH} && chmod +x /app/headscale

COPY . ./


FROM alpine:latest
RUN apk update \
    && apk add --no-cache \
      ca-certificates \
      iptables \
      ip6tables \
      gettext \
      iproute2 \
      squid \
      dante-server \
      python3 \
      dnsmasq \
      caddy \
    && rm -rf /var/cache/apk/*
RUN mkdir -p \
      /var/run/tailscale \
      /var/cache/tailscale \
      /var/lib/tailscale \
      /etc/headscale \
      /etc/squid/

# Copy binary to production image
COPY --from=build /app/default/tailscaled /etc/default/tailscaled
COPY --from=build /app/start.sh /app/start.sh
COPY --from=build /app/headscale /app/headscale
COPY --from=build /app/etc/headscale/config.yaml.template /etc/headscale/config.yaml.template
COPY --from=build /app/tailscaled /app/tailscaled
COPY --from=build /app/tailscale /app/tailscale
COPY --from=build /app/motd /etc/motd
COPY --from=build /app/sockd.conf /etc/sockd.conf
COPY --from=build /app/squid.conf /etc/squid/squid.conf
COPY --from=build /app/dnsmasq.conf /etc/dnsmasq.conf
COPY --from=build /app/Caddyfile /etc/caddy/Caddyfile


# Run on container startup.
USER root
CMD ["/app/start.sh"]
