// Page chrome (lib/widgets/scroll_chrome.dart): a sticky header that
// condenses as the content scrolls, and a bottom bar that slides away while
// scrolling down and comes back on the way up (or at the top).
(function () {
  const { h, icon } = IE;

  /**
   * Header: Back (or [leading]), the title and [actions].
   * Returns {el, setCondensed(bool), setTitle(nodeOrNull)}.
   */
  function header({ title, leading, actions = [], centerTitle = true, back = true, onBack }) {
    const titleEl = h('div', { class: 'header-title', role: 'heading', 'aria-level': '1' }, title);
    const lead = leading !== undefined ? leading
      : back ? IE.iconButton('arrow_back', 'Back', () => (onBack ? onBack() : IE.router.pop())) : null;
    const el = h('header', { class: ['header', centerTitle && 'centered'] },
      lead ? h('div', { class: 'header-leading' }, lead) : h('div', { style: 'width:12px;flex:none' }),
      titleEl,
      h('div', { class: 'header-actions' }, actions));
    let swapped = null;
    return {
      el,
      titleEl,
      setCondensed(c) { el.classList.toggle('condensed', !!c); },
      /** Shows [node] instead of the title (null: back to the title). */
      setTitle(node) {
        if (node === swapped) return;
        swapped = node;
        IE.mount(titleEl, node || title);
      },
    };
  }

  /**
   * Tracks a scroll container and drives the chrome:
   * - navHidden: true while scrolling down (false at the top / scrolling up)
   * - condensed: past condenseAt
   * - titleSwapped: past swapTitleAt (e.g. once the account pills are gone)
   */
  function scrollChrome(scroller, { condenseAt = 4, swapTitleAt = Infinity, onChange }) {
    const state = { navHidden: false, condensed: false, titleSwapped: false };
    let last = 0;
    let swapAt = swapTitleAt;
    function evaluate(fromScroll) {
      const top = scroller.scrollTop;
      const max = scroller.scrollHeight - scroller.clientHeight;
      let hidden = state.navHidden;
      if (fromScroll) {
        const dy = top - last;
        if (dy > 0.5) hidden = true;
        else if (dy < -0.5) hidden = false;
      }
      if (top <= 1 || max <= 1) hidden = false;
      last = top;
      const next = { navHidden: hidden, condensed: top > condenseAt, titleSwapped: top >= swapAt };
      if (next.navHidden !== state.navHidden || next.condensed !== state.condensed || next.titleSwapped !== state.titleSwapped) {
        Object.assign(state, next);
        onChange(state);
      }
    }
    scroller.addEventListener('scroll', () => evaluate(true), { passive: true });
    return {
      state,
      setSwapAt(px) { swapAt = px; evaluate(false); },
      reset() { last = scroller.scrollTop; Object.assign(state, { navHidden: false }); evaluate(false); onChange(state); },
      evaluate: () => evaluate(false),
    };
  }

  /**
   * A page with a sticky condensing header and an auto-hiding bottom bar
   * (ChromeScaffold). opts:
   *   title, actions, leading, back (default true when the router can pop),
   *   onBack, topLevel (no Back), centerTitle (default true),
   *   body (element), bottomBar (element), condensedTitle () => element,
   *   swapTitleAt (px), condenseAt (px)
   * Returns {el, body, header, chrome, setCondensedTitle(fn), setSwapAt(px)}.
   */
  function chromePage(ctx, opts) {
    // Pages under Home always have somewhere to go back to.
    const back = opts.topLevel ? false : (opts.back !== undefined ? opts.back : true);
    const hd = header({
      title: opts.title, actions: opts.actions || [], leading: opts.leading,
      centerTitle: opts.centerTitle !== false, back, onBack: opts.onBack,
    });
    const body = h('div', { class: 'page-body' }, opts.body);
    const barHolder = opts.bottomBar ? h('div', { class: 'bar-holder' }, opts.bottomBar) : null;
    let condensedTitle = opts.condensedTitle || null;
    const chrome = scrollChrome(body, {
      condenseAt: opts.condenseAt != null ? opts.condenseAt : 4,
      swapTitleAt: opts.swapTitleAt != null ? opts.swapTitleAt : Infinity,
      onChange(st) {
        hd.setCondensed(st.condensed);
        hd.setTitle(st.titleSwapped && condensedTitle ? condensedTitle() : null);
        if (barHolder) barHolder.classList.toggle('hidden', st.navHidden);
      },
    });
    const el = h('div', { class: 'col', style: 'height:100%' }, hd.el, body, barHolder);
    return {
      el, body, header: hd, chrome,
      /** Re-renders the condensed title (e.g. after the account changes). */
      setCondensedTitle(fn) {
        condensedTitle = fn;
        hd.setTitle(null);
        if (chrome.state.titleSwapped && fn) hd.setTitle(fn());
      },
      setSwapAt(px) { chrome.setSwapAt(px); },
      setBottomBar(node) { if (barHolder) IE.mount(barHolder, node); },
    };
  }

  /** Watches an element's height (e.g. the account pills) via ResizeObserver. */
  function onHeight(el, fn) {
    if (!window.ResizeObserver) { requestAnimationFrame(() => fn(el.offsetHeight)); return () => {}; }
    const ro = new ResizeObserver(() => fn(el.offsetHeight));
    ro.observe(el);
    return () => ro.disconnect();
  }

  Object.assign(IE, { header, scrollChrome, chromePage, onHeight });
})();
