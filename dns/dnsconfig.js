// @ts-check
/// <reference path=".types.d.ts" />

var ipv4 = '95.217.4.242', ipv6 = '2a01:4f9:c011:4ae2::1';

D('iddqd.uk', NewRegistrar('none'), DnsProvider(NewDnsProvider('cloudflare')), DefaultTTL(1),
  // iddqd.uk (cloudflare pages)
  ALIAS('@', 'index-dx4.pages.dev.', CF_PROXY_ON), // aka CNAME for the CF

  // www.iddqd.uk (redirect to iddqd.uk)
  A('www', '192.0.2.1', CF_PROXY_ON),
  AAAA('www', '100::', CF_PROXY_ON),

  // consul.iddqd.uk
  A('consul', ipv4, CF_PROXY_ON),
  AAAA('consul', ipv6, CF_PROXY_ON),

  // nomad.iddqd.uk
  A('nomad', ipv4, CF_PROXY_ON),
  AAAA('nomad', ipv6, CF_PROXY_ON),

  // proxy.iddqd.uk
  A('proxy', ipv4, CF_PROXY_ON),
  AAAA('proxy', ipv6, CF_PROXY_ON),

  // traefik.iddqd.uk
  A('traefik', ipv4, CF_PROXY_ON),
  AAAA('traefik', ipv6, CF_PROXY_ON),

  // ww1.iddqd.uk (http(2080)+tg(443) proxy)
  A('ww1', ipv4, TTL(86400)),
  AAAA('ww1', ipv6, TTL(86400)),

  // blog.iddqd.uk (github pages)
  CNAME('blog', 'tarampampam.github.io.', CF_PROXY_ON),

  // local.iddqd.uk
  A('local', '127.0.0.1', TTL(86400)),
  AAAA('local', '::1', TTL(86400)),

  // *.local.iddqd.uk
  A('*.local', '127.0.0.1', TTL(86400)),
  AAAA('*.local', '::1', TTL(86400)),

  // email routing (cloudflare)
  MX('@', 1, 'route3.mx.cloudflare.net.'),
  MX('@', 60, 'route2.mx.cloudflare.net.'),
  MX('@', 100, 'route1.mx.cloudflare.net.'),
  TXT('@', 'v=spf1 include:_spf.mx.cloudflare.net ~all'),

  // google site verification
  TXT('@', 'google-site-verification=luYTKgKws2iyH4i2EMVeTvU6cLu3sslERAHtDqZ7G2U'),
);
