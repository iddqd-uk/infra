// @ts-check
/// <reference path=".types.d.ts" />

var IPv4 = '78.47.216.176', IPv6 = '2a01:4f8:1c1c:6019::1';

D('iddqd.uk', NewRegistrar('none'), DnsProvider(NewDnsProvider('cloudflare')), DefaultTTL(1),
  // iddqd.uk (cloudflare pages)
  ALIAS('@', 'index-dx4.pages.dev.', CF_PROXY_ON), // aka CNAME for the CF

  // www.iddqd.uk (redirect to iddqd.uk)
  A('www', '192.0.2.1', CF_PROXY_ON),
  AAAA('www', '100::', CF_PROXY_ON),

  // kube.iddqd.uk
  A('kube', IPv4, TTL(86400)),
  AAAA('kube', IPv6, TTL(86400)),

  // ww2.iddqd.uk (http(HTTP_PROXY_PORT)+tg(443) proxy)
  A('ww2', IPv4, TTL(86400)),
  AAAA('ww2', IPv6, TTL(86400)),

  // wh.iddqd.uk
  A('wh', IPv4, CF_PROXY_ON),
  AAAA('wh', IPv6, CF_PROXY_ON),

  // home.iddqd.uk
  A('home', IPv4, CF_PROXY_ON),
  AAAA('home', IPv6, CF_PROXY_ON),

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
);
