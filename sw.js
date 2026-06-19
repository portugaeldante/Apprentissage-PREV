/* Service worker — VHP « Apprendre la prévention » (projet autonome, séparé de l'outil)
   - PAGE = NETWORK-FIRST : dernière version en ligne, cache en repli hors-ligne.
   - Police + icônes = précachées. Images du cours (cours-img/**, ~18 Mo) = cache RUNTIME (cache-first)
     dès qu'un chapitre est lu en ligne → disponibles hors-ligne ensuite (trop lourd à précacher).
   Cache propre à l'apprentissage : modifier l'outil de prévention ne l'invalide plus (fin des interruptions). */
const CACHE = 'vhp-apprendre-v1';
const IS_LOCAL = (self.location.hostname === 'localhost' || self.location.hostname === '127.0.0.1');
const ASSETS = [
  './',
  'index.html',
  'manifest.webmanifest',
  'icons/icon-192.png',
  'icons/icon-512.png',
  'fonts/inter-latin-400-normal.woff2',
  'fonts/inter-latin-500-normal.woff2',
  'fonts/inter-latin-600-normal.woff2',
  'fonts/inter-latin-700-normal.woff2',
  'fonts/inter-latin-800-normal.woff2'
];

self.addEventListener('install', (event) => {
  if (IS_LOCAL) { self.skipWaiting(); return; }
  event.waitUntil(caches.open(CACHE).then((c) => c.addAll(ASSETS)).then(() => self.skipWaiting()));
});

self.addEventListener('activate', (event) => {
  if (IS_LOCAL) {
    event.waitUntil((async () => {
      try { const ks = await caches.keys(); await Promise.all(ks.map((k) => caches.delete(k))); } catch (e) {}
      try { await self.registration.unregister(); } catch (e) {}
      try { const cs = await self.clients.matchAll({ type: 'window' }); cs.forEach((c) => { try { c.navigate(c.url); } catch (e) {} }); } catch (e) {}
    })());
    return;
  }
  event.waitUntil(caches.keys().then((keys) => Promise.all(keys.filter((k) => k !== CACHE).map((k) => caches.delete(k)))).then(() => self.clients.claim()));
});

self.addEventListener('fetch', (event) => {
  if (IS_LOCAL) return;
  const req = event.request;
  if (req.method !== 'GET') return;
  let url; try { url = new URL(req.url); } catch (e) { return; }

  const isPage = req.mode === 'navigate' || req.destination === 'document'
    || url.pathname === '/' || url.pathname.endsWith('/') || url.pathname.endsWith('index.html');
  if (isPage) {
    event.respondWith(
      fetch(req).then((resp) => {
        if (resp && resp.status === 200) { const copy = resp.clone(); caches.open(CACHE).then((c) => c.put('index.html', copy)); }
        return resp;
      }).catch(() => caches.match('index.html', { ignoreSearch: true }).then((c) => c || caches.match('./')))
    );
    return;
  }

  // Images du cours : cache-first (lourdes), mises en cache au runtime.
  // Autres ressources (polices/icônes/manifest) : cache-first + rafraîchissement en tâche de fond.
  event.respondWith(
    caches.match(req).then((cached) => {
      const network = fetch(req).then((resp) => {
        if (resp && resp.status === 200 && resp.type === 'basic') { const copy = resp.clone(); caches.open(CACHE).then((c) => c.put(req, copy)); }
        return resp;
      }).catch(() => cached);
      return cached || network;
    })
  );
});
