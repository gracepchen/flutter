// Profile (lib/screens/profile_screen.dart): name and tenure, My Premium
// Edge, eDocuments and Account Settings tiles, a link list, a feedback card,
// Sign off, and the prototype's Nav/IA Version switcher.
(function () {
  const { h, icon, mount } = IE;
  const P = IE.data.portfolio;

  IE.route('/profile', (params, ctx) => {
    const since = IE.formatDate(P.investorSince);
    const switcher = h('div', { class: 'profile-switcher' });

    const body = h('div', { class: 'content profile-content' },
      // Header: initials, name, tenure.
      h('button', { type: 'button', class: 'profile-header', 'aria-label': `${P.fullName}, investor since ${since}. Personal details`,
        onclick: () => IE.notBuilt('Personal details') },
      h('span', { class: 'profile-avatar' }, P.firstName[0] + P.lastName[0]),
      h('span', { class: 'grow col', style: 'text-align:left' },
        h('span', { class: 't-heading-sm semibold', style: 'color:var(--gray-900)' }, P.fullName),
        h('span', { class: 't-body-md-book muted', style: 'margin-top:2px' }, `Investor since ${since}`)),
      icon('chevron_right', { color: 'var(--gray-700)' })),
      h('hr', { class: 'divider', style: 'margin:16px 0' }),
      h('button', { type: 'button', class: 'profile-premium', 'aria-label': 'My Premium Edge', onclick: () => IE.notBuilt('My Premium Edge') },
        icon('star', { fill: true, color: 'var(--gray-0)' }), h('span', { class: 't-body-lg semibold' }, 'My Premium Edge')),
      h('div', { class: 'profile-tiles' },
        tile('description', 'eDocuments', () => IE.router.push(IE.routes.eDocuments)),
        tile('settings', 'Account Settings', () => IE.router.push(IE.routes.accountSettings))),
      h('div', { class: 'profile-links' },
        [['add_circle', 'Add account', () => IE.showAddAccountSheet()],
          ['inventory_2', 'Forms Centre', () => IE.notBuilt('Forms Centre')],
          ['shield', 'Legal and more', () => IE.notBuilt('Legal and more')]].map(([ic, label, fn], i) => [
          i > 0 ? h('hr', { class: 'divider' }) : null,
          h('button', { type: 'button', class: 'profile-link', 'aria-label': label, onclick: fn },
            icon(ic, { color: 'var(--gray-700)' }), h('span', { class: 'grow t-body-lg', style: 'color:var(--gray-900);text-align:left' }, label)),
        ])),
      h('div', { class: 'profile-feedback' },
        h('div', { class: 'grow col' },
          h('h2', { class: 't-body-lg semibold', style: 'margin:0;color:var(--gray-900)' }, 'Your opinion matters'),
          h('div', { class: 't-body-md-book muted', style: 'margin-top:4px' }, 'Help us improve your investing experience'),
          h('div', { style: 'margin-top:16px' },
            h('button', { type: 'button', class: 'profile-feedback-btn', onclick: () => IE.notBuilt('Share feedback') }, 'Share feedback >'))),
        h('span', { class: 'profile-bulb' }, icon('lightbulb', { fill: true, size: 48, color: 'var(--gray-700)' }))),
      h('button', { type: 'button', class: 'profile-signoff', onclick: () => {
        // go replaces the whole stack, so Back can't return to the app.
        IE.store.set('signedIn', false);
        IE.store.set('pendingLocation', null);
        IE.router.go(IE.routes.signOn);
      } }, 'Sign off'),
      switcher);

    function renderSwitcher() {
      const cur = IE.store.get('navVersion');
      // C (the default) first, then B, A and D.
      const versions = [['actions', 'C: Search with actions'], ['shortcuts', 'B: Search with shortcuts'],
        ['searchOnly', 'A: Search only'], ['tabs', 'D: Tabs']];
      mount(switcher,
        h('h2', { class: 't-heading-xs', style: 'margin:0 0 16px' }, 'Nav/IA Version'),
        versions.map(([key, label]) => h('button', {
          type: 'button', class: ['profile-version', key === cur && 'selected'], 'aria-pressed': String(key === cur),
          onclick: () => IE.store.set('navVersion', key),
        }, label)));
    }
    renderSwitcher();
    ctx.watch('navVersion', renderSwitcher);

    const page = IE.chromePage(ctx, {
      title: 'Profile',
      // A plain app bar in Flutter: it doesn't condense.
      condenseAt: Infinity,
      actions: [
        IE.iconButton('dark_mode', 'Dark mode', () => IE.notBuilt('Dark mode')),
        IE.iconButton('contact_support', 'Help', () => IE.router.push(IE.routes.help)),
      ],
      body,
    });
    return page.el;
  });

  /** Outlined tile: an icon over a label. */
  function tile(ic, label, onTap) {
    return h('button', { type: 'button', class: 'profile-tile', 'aria-label': label, onclick: onTap },
      icon(ic, { size: 32, color: 'var(--gray-800)' }),
      h('span', { class: 't-body-lg', style: 'color:var(--gray-900);margin-top:16px;white-space:nowrap' }, label));
  }
})();
