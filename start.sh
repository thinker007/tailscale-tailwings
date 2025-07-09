#!/bin/sh

echo 'Starting up Tailscale...'

# error: adding [-i tailscale0 -j MARK --set-mark 0x40000] in v4/filter/ts-forward: running [/sbin/iptables -t filter -A ts-forward -i tailscale0 -j MARK --set-mark 0x40000 --wait]: exit status 2: iptables v1.8.6 (legacy): unknown option "--set-mark"
modprobe xt_mark

echo 'net.ipv4.ip_forward = 1' | tee -a /etc/sysctl.conf
echo 'net.ipv6.conf.all.forwarding = 1' | tee -a /etc/sysctl.conf
#echo 'net.ipv6.conf.all.disable_policy = 1' | tee -a /etc/sysctl.conf
sysctl -p /etc/sysctl.conf

iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
ip6tables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

# --tun=userspace-networking --socks5-server=localhost:3215

TS_DEBUG_ALWAYS_USE_DERP=true /app/tailscaled --verbose=1 --port 41641 &
sleep 5
if [ ! -S /var/run/tailscale/tailscaled.sock ]; then
    echo "tailscaled.sock does not exist. exit!"
    exit 1
fi

if [ -n "${TAILSCALE_AUTH_KEY}" ]; then
    /app/tailscale up \
        --authkey=${TAILSCALE_AUTH_KEY} \
        --hostname=entrance-${FLY_REGION} \
        --advertise-exit-node \
        --ssh
else
    /app/tailscale up \
        --hostname=entrance-${FLY_REGION} \
        --advertise-exit-node
fi

echo 'Tailscale started'

echo 'Starting Squid...'

squid &

echo 'Squid started'

echo 'Starting Dante...'

sockd &

echo 'Dante started'

echo 'Starting dnsmasq...'

dnsmasq &

echo 'dnsmasq started'

echo 'Starting headscale'
# 使用环境变量替换模板
envsubst < /etc/headscale/config.yml.template > /etc/headscale/config.yaml
/app/headscale serve -c /etc/headscale/config.yaml &
echo 'headscale started'

#echo 'Starting Caddy'
#caddy run --config /etc/caddy/Caddyfile &
#echo 'Caddy started'


sleep infinity
