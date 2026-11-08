// Cloudflare Worker: looks up a Google Maps share link and returns the place.
// Used by maps-converter.html. Paste this whole file into the Cloudflare Worker editor.
//
//   GET https://<your-worker>.workers.dev/?url=<google maps link>
//   -> {"ok":true,"name":"Bullring","address":"Birmingham B5 4BU, UK","lat":52.477,"lng":-1.894,"resolvedUrl":"..."}
//
// It only accepts Google Maps links, so it cannot be used to fetch anything else.

const GOOGLE_HOST = /^((www|maps)\.)?google\.[a-z]{2,3}(\.[a-z]{2})?$/;

function isGoogleMaps(u) {
  const h = u.hostname;
  if (h === 'maps.app.goo.gl') return true;
  if (h === 'goo.gl' || h === 'g.co') return true; // goo.gl/maps/..., g.co/kgs/...
  if (h === 'consent.google.com') return true;     // cookie-consent hop
  return GOOGLE_HOST.test(h) && (h.startsWith('maps.') || u.pathname.startsWith('/maps') || u.pathname === '/');
}

// Pull a place out of a long Google Maps URL.
export function fromUrl(href) {
  const out = {};
  let u;
  try { u = new URL(href); } catch { return out; }
  const pin = href.match(/!3d(-?\d+(?:\.\d+)?)!4d(-?\d+(?:\.\d+)?)/);
  const view = u.pathname.match(/@(-?\d+(?:\.\d+)?),(-?\d+(?:\.\d+)?)/);
  const place = u.pathname.match(/\/maps\/place\/([^/]+)/);
  const q = u.searchParams.get('q') || u.searchParams.get('query');
  if (pin) { out.lat = +pin[1]; out.lng = +pin[2]; }
  else if (view) { out.lat = +view[1]; out.lng = +view[2]; }
  if (place) out.name = decodeURIComponent(place[1].replace(/\+/g, ' '));
  if (q) {
    const c = q.match(/^\s*(-?\d+(?:\.\d+)?)\s*,\s*(-?\d+(?:\.\d+)?)\s*$/);
    if (c) { if (out.lat == null) { out.lat = +c[1]; out.lng = +c[2]; } }
    else if (!out.name) out.name = q;
  }
  return out;
}

function decodeEntities(s) {
  return s.replace(/&#(\d+);/g, (_, n) => String.fromCharCode(+n))
    .replace(/&#x([0-9a-f]+);/gi, (_, n) => String.fromCharCode(parseInt(n, 16)))
    .replace(/&quot;/g, '"').replace(/&#39;|&apos;/g, "'").replace(/&lt;/g, '<').replace(/&gt;/g, '>').replace(/&amp;/g, '&');
}

function meta(html, prop) {
  const a = html.match(new RegExp('<meta[^>]+content="([^"]*)"[^>]+(?:property|itemprop|name)="' + prop + '"', 'i'));
  const b = html.match(new RegExp('<meta[^>]+(?:property|itemprop|name)="' + prop + '"[^>]+content="([^"]*)"', 'i'));
  return (a || b) ? decodeEntities((a || b)[1]) : '';
}

// Pull a place out of a Google Maps place page.
export function fromHtml(html) {
  const out = {};
  let title = meta(html, 'og:title') || meta(html, 'name');
  if (!title) { const t = html.match(/<title>([^<]*)<\/title>/i); if (t) title = decodeEntities(t[1]).replace(/\s*-\s*Google Maps\s*$/, ''); }
  if (title && title !== 'Google Maps') {
    const parts = title.split(' · ');
    out.name = parts[0].trim();
    if (parts[1]) out.address = parts.slice(1).join(', ').trim();
  }
  const img = meta(html, 'og:image') || meta(html, 'image');
  const c = (img + ' ' + html.slice(0, 200000)).match(/(?:center|markers)=(-?\d+\.\d+)(?:%2C|,)(-?\d+\.\d+)/)
    || html.match(/\[null,null,(-?\d{1,2}\.\d{3,}),(-?\d{1,3}\.\d{3,})\]/);
  if (c) { out.lat = +c[1]; out.lng = +c[2]; }
  return out;
}

const HEADERS = {
  'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15',
  'Accept-Language': 'en-GB,en;q=0.9',
  // Skip Google's cookie-consent screen (shown in the UK and EU).
  'Cookie': 'SOCS=CAESEwgDEgk0ODE3Nzk3MjQaAmVuIAEaBgiA_LyaBg; CONSENT=YES+',
};

function reply(body, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*', 'Cache-Control': 'public, max-age=86400' },
  });
}

export default {
  async fetch(request) {
    if (request.method === 'OPTIONS') {
      return new Response(null, { headers: { 'Access-Control-Allow-Origin': '*', 'Access-Control-Allow-Methods': 'GET' } });
    }
    const link = new URL(request.url).searchParams.get('url');
    if (!link) return reply({ ok: false, error: 'Add ?url=<Google Maps link>' }, 400);

    let current;
    try { current = new URL(link); } catch { return reply({ ok: false, error: 'That is not a valid link.' }, 400); }
    if (!isGoogleMaps(current)) return reply({ ok: false, error: 'Only Google Maps links are accepted.' }, 400);

    const found = {};
    const merge = (x) => { for (const k in x) if (found[k] == null && x[k] != null && x[k] !== '') found[k] = x[k]; };

    // Follow redirects ourselves so every hop can be checked for a place.
    let res;
    for (let hop = 0; hop < 8; hop++) {
      merge(fromUrl(current.href));
      if (found.lat != null && found.name) { res = null; break; } // already have the place
      res = await fetch(current.href, { headers: HEADERS, redirect: 'manual' });
      const next = res.headers.get('Location');
      if (!(res.status >= 300 && res.status < 400 && next)) break;
      current = new URL(next, current);
      // The consent page carries the real link in ?continue=
      if (current.hostname === 'consent.google.com' && current.searchParams.get('continue')) {
        current = new URL(current.searchParams.get('continue'));
      }
      if (!isGoogleMaps(current)) return reply({ ok: false, error: 'The link led away from Google Maps.' }, 400);
    }

    if (res && res.ok && (found.lat == null || !found.name)) {
      merge(fromHtml(await res.text()));
    }

    if (found.lat == null && !found.name) {
      return reply({ ok: false, error: 'Google did not say which place this is.', resolvedUrl: current.href }, 404);
    }
    return reply({ ok: true, ...found, resolvedUrl: current.href });
  },
};
