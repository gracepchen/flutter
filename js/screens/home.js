// Home / Portfolio ('/') (lib/screens/home/home_screen.dart): greeting with
// Notifications and Profile, then the widgets. The bottom bar always shows
// on Home (no auto-hide, no sticky header). Back on Home asks before
// signing off, since it's the bottom of the stack.
(function () {
  const { h } = IE;
  const R = IE.routes;

  function greeting(now) {
    if (now.getHours() < 12) return 'Good morning';
    if (now.getHours() < 18) return 'Good afternoon';
    return 'Good evening';
  }

  async function confirmSignOff() {
    const choice = await IE.showDialog({
      title: 'Are you sure you want to sign off?',
      actions: [
        { label: 'Sign off', value: 'signoff' },
        { label: 'Cancel', value: 'cancel', kind: 'filled' },
      ],
    });
    if (choice !== 'signoff') return;
    IE.store.set('signedIn', false);
    IE.store.set('pendingLocation', null);
    IE.router.go(R.signOn);
  }

  IE.route('/', (params, ctx) => {
    const W = IE.home;
    const header = h('div', { class: 'home-header' },
      h('h1', { class: 'home-greeting grow' }, `${greeting(new Date())}, ${IE.data.portfolio.firstName}.`),
      IE.iconButton('notifications', "Notifications and what's new", () => IE.router.push(R.notifications), { class: 'round-gray' }),
      IE.iconButton('person', 'Profile and settings', () => IE.router.push(R.profile), { class: 'round-gray' }));

    const list = h('div', { class: 'content home-list' },
      header,
      h('div', { class: 'home-gap32' }),
      W.portfolioSummary(ctx),
      h('div', { class: 'home-gap32' }),
      W.accountsCard(ctx),
      h('div', { class: 'home-gap24' }),
      W.holdingsCard(ctx),
      h('div', { class: 'home-gap24' }),
      // Watchlists right under Holdings.
      W.watchlistsCard(),
      h('div', { class: 'home-gap24' }),
      W.offersCarousel(),
      h('div', { class: 'home-gap24' }),
      W.recentActivityCard(),
      h('div', { class: 'home-gap32' }),
      W.autoInvestingCard(),
      h('div', { class: 'home-gap16' }),
      W.financialProgressCard(ctx));

    ctx.setPopHandler(() => { confirmSignOff(); return true; });

    return h('div', { class: 'col home-page', style: 'height:100%' },
      h('div', { class: 'page-body' }, list),
      IE.navBar(ctx, { current: 'home' }));
  });
})();
