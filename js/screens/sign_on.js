// Sign On and Signing in (lib/screens/sign_on/*). Sign-on is simulated: the
// button shows the signing-in screen (the Investor's Edge mark turning
// slowly), then Home, or the page an app shortcut was waiting to open.
(function () {
  const { h } = IE;
  const R = IE.routes;

  IE.route('/sign-on', () => h('div', { class: 'signon-page' },
    h('button', {
      type: 'button', class: 'signon-btn',
      onclick: () => { IE.haptic(); IE.router.go(R.signingIn); },
    }, 'Sign on')));

  IE.route('/signing-in', (params, ctx) => {
    ctx.timeout(() => {
      IE.store.set('signedIn', true);
      const pending = IE.store.get('pendingLocation');
      IE.store.set('pendingLocation', null);
      IE.router.go(pending || R.home);
    }, 900);
    return h('div', { class: 'signon-page signing', role: 'status', 'aria-live': 'polite', 'aria-label': 'Signing on' },
      h('div', { class: 'signon-mark' }, IE.ieMark(128)));
  });
})();
