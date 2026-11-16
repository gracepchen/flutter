// Starts the prototype. Opens on Sign On, or on the page in the URL hash
// (e.g. index.html#/holdings), which counts as signed on.
(function () {
  const hash = decodeURIComponent((location.hash || '').replace(/^#/, ''));
  const known = hash && hash.startsWith('/') && hash !== IE.routes.signingIn;
  const initial = known ? hash : IE.routes.signOn;
  if (initial !== IE.routes.signOn) IE.store.set('signedIn', true);
  IE.router.start(document.getElementById('app'), initial);
})();
