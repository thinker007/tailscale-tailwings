Tailscale Tailwings
===================

This is a container image that runs a Tailscale exit node and proxy servers
to work as a 'personal VPN' service, that can be deployed using Fly.io or
other container hosting platforms.

This is a fork of [patte/fly-tailscale-exit](https://github.com/patte/fly-tailscale-exit/)
with some minor fixes and additions, like Squid and Dante to acts as proxies.


Usage
-----
The original [documentation](./docs.md) can help you to set this up on Fly.io.

To use the proxies, you can use the `tailscale ip` that has been given to the node;
  * port `3214` is the Squid HTTP proxy
  * port `3215` is the Dante SOCKS5 proxy

You can also use `ssh` to connect to the node with the `-D` option or `sshuttle`.

