// CCST Crew offline cache. Bump VERSION when the app files change.
const VERSION = "crew-v1";
const SHELL = ["./", "index.html", "config.js", "manifest.webmanifest", "../icons/icon-180.png", "../icons/icon-192.png", "../icons/icon-512.png"];
self.addEventListener("install", e => {
  e.waitUntil(caches.open(VERSION).then(c => c.addAll(SHELL)).then(() => self.skipWaiting()));
});
self.addEventListener("activate", e => {
  // Only clear this app's old caches (the personal app and the Reader cache share this site).
  e.waitUntil(caches.keys().then(keys => Promise.all(keys.filter(k => k.startsWith("crew-v") && k !== VERSION).map(k => caches.delete(k)))).then(() => self.clients.claim()));
});
self.addEventListener("fetch", e => {
  const url = new URL(e.request.url);
  if (e.request.method !== "GET") return;
  // Server calls (Supabase, GitHub) are never cached here; the app stores data itself.
  if (url.origin === location.origin && url.pathname.includes("/crew/")) {
    e.respondWith(fetch(e.request, {cache: "no-cache"}).then(r => { const copy = r.clone(); caches.open(VERSION).then(c => c.put(e.request, copy)); return r; })
      .catch(() => caches.match(e.request).then(r => r || caches.match("index.html"))));
    return;
  }
  if (url.origin === location.origin && url.pathname.includes("/icons/")) {
    e.respondWith(caches.match(e.request).then(r => r || fetch(e.request)));
    return;
  }
  if (url.hostname.endsWith("googleapis.com") || url.hostname.endsWith("gstatic.com")) {
    e.respondWith(caches.match(e.request).then(r => r || fetch(e.request).then(res => { const copy = res.clone(); caches.open(VERSION).then(c => c.put(e.request, copy)); return res; })));
  }
});
