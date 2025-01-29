// @ts-check
/// <reference path=".types.d.ts" />

var legacyIPv4 = '95.217.4.242', legacyIPv6 = '2a01:4f9:c011:4ae2::1';
var kubeIPv4 = '78.47.216.176', kubeIPv6 = '2a01:4f8:1c1c:6019::1';

D('iddqd.uk', NewRegistrar('none'), DnsProvider(NewDnsProvider('cloudflare')), DefaultTTL(1),
  // iddqd.uk (cloudflare pages)
  ALIAS('@', 'index-dx4.pages.dev.', CF_PROXY_ON), // aka CNAME for the CF

  // www.iddqd.uk (redirect to iddqd.uk)
  A('www', '192.0.2.1', CF_PROXY_ON),
  AAAA('www', '100::', CF_PROXY_ON),

  // kube.iddqd.uk
  A('kube', kubeIPv4, TTL(86400)),
  AAAA('kube', kubeIPv6, TTL(86400)),

  // ww2.iddqd.uk (http(HTTP_PROXY_PORT)+tg(443) proxy)
  A('ww2', kubeIPv4, TTL(86400)),
  AAAA('ww2', kubeIPv6, TTL(86400)),

  // ww1.iddqd.uk (http(2080)+tg(443) proxy) // TODO: remove
  A('ww1', legacyIPv4, TTL(86400)),
  AAAA('ww1', legacyIPv6, TTL(86400)),

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
