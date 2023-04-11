ARG TSVERSION=1.38.4
ARG TSFILE=tailscale_${TSVERSION}_amd64.tgz

FROM alpine:latest as build
ARG TSFILE
WORKDIR /app

RUN wget https://pkgs.tailscale.com/stable/${TSFILE} && \
  tar xzf ${TSFILE} --strip-components=1
COPY . ./


FROM alpine:latest
RUN apk update && apk add ca-certificates iptables ip6tables iproute2 dante-server && rm -rf /var/cache/apk/*

# Copy binary to production image
COPY --from=build /app/start.sh /app/start.sh
COPY --from=build /app/tailscaled /app/tailscaled
COPY --from=build /app/tailscale /app/tailscale
COPY --from=build /app/sockd.conf /etc/sockd.conf
RUN mkdir -p /var/run/tailscale
RUN mkdir -p /var/cache/tailscale
RUN mkdir -p /var/lib/tailscale

# Run on container startup.
USER root
CMD ["/app/start.sh"]
