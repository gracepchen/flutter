// Shared UI: overlays (sheets, dialogs, snackbars) and the OBR widgets used
// on more than one screen.
(function () {
  const { h, icon, mount } = IE;

  // ── Overlays ──
  const overlays = [];
  function overlayRoot() {
    let r = document.querySelector('#app > .overlay-root');
    if (!r) { r = h('div', { class: 'overlay-root' }); document.getElementById('app').appendChild(r); }
    return r;
  }

  function registerOverlay(close) {
    const entry = { close };
    overlays.push(entry);
    return () => { const i = overlays.indexOf(entry); if (i >= 0) overlays.splice(i, 1); };
  }
  /** Closes the topmost sheet/dialog/overlay. True if one was open. */
  IE.closeTopOverlay = function () {
    const top = overlays[overlays.length - 1];
    if (!top) return false;
    top.close();
    return true;
  };
  IE.closeOverlays = function () { while (overlays.length) overlays[overlays.length - 1].close(); };

  /**
   * Modal bottom sheet over a dark scrim. [content] is an element or
   * (close) => element. Resolves with the value passed to close().
   */
  function showSheet(content, opts = {}) {
    return new Promise((resolve) => {
      const root = overlayRoot();
      const scrim = h('div', { class: 'scrim', onclick: () => close() });
      let done = false;
      const sheet = h('div', { class: 'sheet', role: 'dialog', 'aria-modal': 'true', 'aria-label': opts.label || null });
      const unregister = registerOverlay(() => close());
      function close(value) {
        if (done) return;
        done = true;
        unregister();
        scrim.classList.remove('open');
        sheet.classList.remove('open');
        setTimeout(() => { scrim.remove(); sheet.remove(); }, IE.reduceMotion() ? 0 : 260);
        if (opts.onClose) opts.onClose(value);
        resolve(value);
      }
      const body = typeof content === 'function' ? content(close) : content;
      if (opts.dragHandle !== false) sheet.appendChild(h('div', { class: 'handle', 'aria-hidden': 'true' }));
      else sheet.appendChild(h('div', { style: 'height:16px;flex:none' }));
      sheet.appendChild(h('div', { class: 'sheet-body' }, body));
      root.append(scrim, sheet);
      requestAnimationFrame(() => requestAnimationFrame(() => { scrim.classList.add('open'); sheet.classList.add('open'); }));
    });
  }

  /**
   * Alert dialog: showDialog({title, actions: [{label, value, kind}]}).
   * kind: 'text' (default) or 'filled'. Resolves with the action's value
   * (undefined when dismissed).
   */
  function showDialog({ title, body, actions }) {
    return new Promise((resolve) => {
      const root = overlayRoot();
      const scrim = h('div', { class: 'scrim', onclick: () => close() });
      let done = false;
      const dialog = h('div', { class: 'dialog', role: 'alertdialog', 'aria-modal': 'true', 'aria-label': title },
        h('h2', null, title),
        body || null,
        h('div', { class: 'actions' }, actions.map((a) => h('button', {
          class: ['btn', a.kind === 'filled' ? 'filled' : 'text'],
          style: a.kind === 'filled' ? 'border-radius:999px' : null,
          onclick: () => close(a.value),
        }, a.label))));
      const wrap = h('div', { class: 'dialog-wrap', onclick: (e) => { if (e.target === wrap) close(); } }, dialog);
      const unregister = registerOverlay(() => close());
      function close(value) {
        if (done) return;
        done = true;
        unregister();
        scrim.classList.remove('open');
        dialog.classList.remove('open');
        setTimeout(() => { scrim.remove(); wrap.remove(); }, IE.reduceMotion() ? 0 : 200);
        resolve(value);
      }
      root.append(scrim, wrap);
      requestAnimationFrame(() => requestAnimationFrame(() => { scrim.classList.add('open'); dialog.classList.add('open'); }));
      const first = dialog.querySelector('button');
      if (first) first.focus({ preventScroll: true });
    });
  }

  let snackTimer = null;
  /** Snackbar (replaces any one showing). */
  function toast(text) {
    const root = overlayRoot();
    let bar = root.querySelector('.snackbar');
    if (!bar) { bar = h('div', { class: 'snackbar', role: 'status', 'aria-live': 'polite' }); root.appendChild(bar); }
    bar.textContent = text;
    requestAnimationFrame(() => bar.classList.add('open'));
    clearTimeout(snackTimer);
    snackTimer = setTimeout(() => bar.classList.remove('open'), 4000);
  }
  function notBuilt(what) { toast(`${what} is not built yet in this prototype.`); }

  // ── Blocks ──
  function card(children, opts = {}) {
    return h(opts.onClick ? 'button' : 'div', {
      class: ['card', opts.onClick && 'tappable', opts.class],
      style: Object.assign({}, opts.padding != null ? { padding: opts.padding } : {}, opts.radius ? { borderRadius: opts.radius } : {}, opts.style || {}),
      onclick: opts.onClick || null,
      type: opts.onClick ? 'button' : null,
      'aria-label': opts.label || null,
    }, children);
  }

  /** Card title with an optional "See all ›" link. */
  function sectionHeader(title, onSeeAll, seeAllLabel) {
    return h('div', { class: 'section-header' },
      h('h2', null, title),
      onSeeAll ? h('button', { class: 'see-all', onclick: onSeeAll, 'aria-label': seeAllLabel || 'See all' },
        'See all', icon('chevron_right', { size: 18 })) : null);
  }

  /** Informational banner (blue) that flags unbuilt prototype areas. */
  function notice(message) {
    return h('div', { class: 'notice', role: 'note' }, icon('info'), h('div', { class: 'grow' }, message));
  }

  /** The placeholder body: icon circle, title, summary, planned list, notice. */
  function placeholderContent({ title, iconName, initials, summary, planned = [], extra, footer, showHeader = true }) {
    return h('div', { class: 'col' },
      showHeader ? [
        h('div', { class: ['ph-circle', initials && 'initials'] }, initials ? initials : icon(iconName || 'info')),
        h('h1', { class: 't-display-sm semibold', style: 'margin:16px 0 8px' }, title),
      ] : null,
      h('p', { class: 't-body-lg-book', style: 'margin:0;color:var(--gray-700)' }, summary),
      extra ? h('div', { class: 'mt16' }, extra) : null,
      planned.length ? h('div', { class: 'card ph-planned' },
        h('div', { class: 'eyebrow' }, 'PLANNED FOR THIS SCREEN'),
        h('ul', null, planned.map((p) => h('li', null, p)))) : null,
      h('div', { class: 'mt24' }, notice('Prototype placeholder. This screen is not designed or connected to live data yet.')),
      footer ? h('div', { class: 'mt24' }, footer) : null,
    );
  }

  // ── Controls ──
  /**
   * Segmented control (2–4 options) with a sliding dark thumb.
   * Returns an element with .select(i) to change it from outside.
   */
  function segmented({ labels, selected = 0, onSelect, light = false, radius, label }) {
    const thumb = h('div', { class: 'seg-thumb', style: { width: `calc((100% - 8px) / ${labels.length})` } });
    const buttons = labels.map((l, i) => h('button', {
      type: 'button', role: 'tab', 'aria-selected': String(i === selected),
      onclick: () => { if (i !== cur) { set(i); IE.haptic(); onSelect && onSelect(i); } },
    }, l));
    const el = h('div', { class: ['seg', light && 'light'], role: 'tablist', 'aria-label': label || null, style: radius ? { borderRadius: radius } : null }, thumb, buttons);
    let cur = selected;
    function set(i) {
      cur = i;
      thumb.style.transform = `translateX(${i * 100}%)`;
      buttons.forEach((b, j) => { b.classList.toggle('selected', i === j); b.setAttribute('aria-selected', String(i === j)); });
    }
    set(selected);
    el.select = set;
    return el;
  }

  /** Full-width underline tabs. Returns an element with .select(i). */
  function underlineTabs({ labels, selected = 0, onSelect }) {
    const bar = h('div', { class: 'bar', style: { width: `${100 / labels.length}%` } });
    let cur = selected;
    const buttons = labels.map((l, i) => h('button', {
      type: 'button', role: 'tab',
      onclick: () => { if (i !== cur) { set(i); IE.haptic(); onSelect && onSelect(i); } },
    }, l));
    const el = h('div', { class: 'utabs', role: 'tablist' }, buttons, bar);
    function set(i) {
      cur = i;
      bar.style.transform = `translateX(${i * 100}%)`;
      buttons.forEach((b, j) => { b.classList.toggle('selected', i === j); b.setAttribute('aria-selected', String(i === j)); });
    }
    set(selected);
    el.select = set;
    return el;
  }

  /** Oval two-way toggle; tapping anywhere flips it. */
  function pillToggle({ left, right, rightSelected = false, onChange, segmentWidth = 76 }) {
    let on = rightSelected;
    const thumb = h('div', { class: 'thumb', style: { width: segmentWidth } });
    const l = h('span', { class: 'lbl', style: { width: segmentWidth } }, left);
    const r = h('span', { class: 'lbl', style: { width: segmentWidth } }, right);
    const btn = h('button', { type: 'button', class: 'pill-toggle', onclick: () => { set(!on); IE.haptic(); onChange && onChange(on); } },
      h('span', { class: 'track' }, thumb, l, r));
    function set(v) {
      on = v;
      thumb.style.transform = on ? `translateX(${segmentWidth}px)` : 'none';
      l.classList.toggle('on', !on); r.classList.toggle('on', on);
      btn.setAttribute('aria-label', `Showing ${on ? right : left}. Switch to ${on ? left : right}`);
      btn.setAttribute('aria-pressed', String(on));
    }
    set(on);
    btn.set = set;
    return btn;
  }

  /** Row of time-range pills under a chart. ranges: [{label, spoken}]. */
  function rangeSelector({ ranges, selected = 0, onSelect }) {
    let cur = selected;
    const buttons = ranges.map((r, i) => h('button', {
      type: 'button', 'aria-label': r.spoken,
      onclick: () => { if (i !== cur) { set(i); IE.haptic(); onSelect && onSelect(i); } },
    }, h('span', { class: 'chip' }, r.label)));
    const el = h('div', { class: 'ranges' }, buttons);
    function set(i) { cur = i; buttons.forEach((b, j) => { b.classList.toggle('selected', i === j); b.setAttribute('aria-pressed', String(i === j)); }); }
    set(selected);
    el.select = set;
    return el;
  }

  /**
   * Area line chart that draws on from left to right (instant under reduced
   * motion). opts: points, lineColor, fillColor, height, label, animate.
   */
  function lineChart({ points, lineColor = 'var(--green-500)', fillColor = '#76B297', height = 180, label = '', animate = true }) {
    const W = 1000, H = 1000;
    const min = Math.min(...points), max = Math.max(...points);
    const range = max - min || 1;
    const top = 8;
    const plot = H * 0.8 - top;
    const x = (i) => i / (points.length - 1) * W;
    const y = (v) => top + (1 - (v - min) / range) * plot;
    let d = `M${x(0)} ${y(points[0])}`;
    for (let i = 1; i < points.length; i++) d += ` L${x(i).toFixed(2)} ${y(points[i]).toFixed(2)}`;
    const gid = 'g' + Math.random().toString(36).slice(2, 8);
    const line = IE.s('path', { d, fill: 'none', stroke: lineColor, 'stroke-width': 1.5, 'vector-effect': 'non-scaling-stroke', 'stroke-linejoin': 'round', 'stroke-linecap': 'round', pathLength: 1 });
    const fill = IE.s('path', { d: d + ` L${W} ${H} L0 ${H} Z`, fill: `url(#${gid})` });
    const svg = IE.s('svg', { viewBox: `0 0 ${W} ${H}`, preserveAspectRatio: 'none', width: '100%', height, role: 'img', 'aria-label': label, style: { display: 'block', overflow: 'visible' } },
      IE.s('defs', null, IE.s('linearGradient', { id: gid, x1: 0, y1: 0, x2: 0, y2: 1 },
        IE.s('stop', { offset: '0%', 'stop-color': fillColor, 'stop-opacity': 0.30 }),
        IE.s('stop', { offset: '100%', 'stop-color': fillColor, 'stop-opacity': 0.06 }))),
      fill, line);
    if (animate && !IE.reduceMotion()) {
      line.style.strokeDasharray = '1';
      line.style.strokeDashoffset = '1';
      fill.style.opacity = '0';
      requestAnimationFrame(() => requestAnimationFrame(() => {
        line.style.transition = 'stroke-dashoffset 600ms cubic-bezier(0,0,.58,1)';
        fill.style.transition = 'opacity 600ms cubic-bezier(0,0,.58,1)';
        line.style.strokeDashoffset = '0';
        fill.style.opacity = '1';
      }));
    }
    return svg;
  }

  /** "Add an account" sheet: open, link or transfer (none built yet). */
  function showAddAccountSheet() {
    return showSheet((close) => {
      const option = (ic, label, what) => h('button', { class: 'sheet-option', onclick: () => { close(); notBuilt(what); } },
        icon(ic, { color: 'var(--brand-600)' }), h('span', { class: 'lbl' }, label), icon('chevron_right', { color: 'var(--gray-500)' }));
      return h('div', { style: 'padding:0 8px 16px' },
        h('h2', { class: 'sheet-title', style: 'padding:0 16px 8px' }, 'Add an account'),
        option('add', 'Open a new account', 'Opening an account'),
        option('link', 'Link an existing account', 'Linking an account'),
        option('move_down', 'Transfer account from another brokerage', 'Transferring an account'));
    }, { label: 'Add an account' });
  }

  /** Sub-account views of a selected account. */
  const SubAccountView = {
    combined: { key: 'combined', currency: 'CAD', spoken: 'Combined' },
    cad: { key: 'cad', currency: 'CAD', spoken: 'Canadian dollar holdings' },
    usd: { key: 'usd', currency: 'USD', spoken: 'US dollar holdings' },
  };
  /** 'cad' | 'usd' | null for query strings. */
  const subParam = (sub) => (sub === 'cad' || sub === 'usd' ? sub : null);

  /**
   * Account pills: All, then each account ("TFSA 58204417"), scrolling
   * sideways; a dropdown at 6+ accounts. With onSubAccount, the selected
   * pill grows into name / CAD flag / USD flag segments.
   *
   * Returns an element with .update(props) that re-renders it in place,
   * keeping the scroll position and revealing the selected pill.
   */
  function accountFilter(props) {
    const el = h('div', { class: 'acct-filter' });
    let p = Object.assign({ subAccount: 'combined', onSubAccount: null, showAddAccount: true }, props);

    function render(animate) {
      const prevRow = el.querySelector('.acct-pills');
      const prevScroll = prevRow ? prevRow.scrollLeft : 0;
      const { accounts, selected, onSelected, subAccount, onSubAccount, showAddAccount } = p;
      if (accounts.length >= 6) {
        const sel = h('select', { 'aria-label': 'Account', onchange: (e) => {
          const v = e.target.value;
          if (v === '__add__') { e.target.value = selected || ''; showAddAccountSheet(); } else onSelected(v || null);
        } },
        h('option', { value: '', selected: selected == null }, 'All accounts'),
        accounts.map((a) => h('option', { value: a.name, selected: selected === a.name }, a.label)),
        showAddAccount ? h('option', { value: '__add__' }, '+ Add account') : null);
        mount(el, h('div', { class: 'acct-dropdown' }, sel),
          selected && onSubAccount ? h('div', { class: 'acct-pills', style: 'margin-top:8px' }, selectedPill(accounts.find((a) => a.name === selected), subAccount, onSubAccount)) : null);
        return;
      }
      const row = h('div', { class: 'acct-pills' },
        pill('All', selected == null, () => onSelected(null), selected == null),
        accounts.map((a) => (selected === a.name && onSubAccount)
          ? selectedPill(a, subAccount, onSubAccount)
          : pill(a.label, selected === a.name, () => onSelected(a.name), selected === a.name)),
        showAddAccount ? h('button', { type: 'button', class: 'acct-pill add', onclick: () => showAddAccountSheet(), 'aria-label': 'Add account' },
          icon('add', { size: 20 }), 'Add account') : null);
      mount(el, row);
      row.scrollLeft = prevScroll;
      requestAnimationFrame(() => {
        const target = row.querySelector('[data-selected]');
        if (!target) return;
        const left = target.offsetLeft - (row.clientWidth - target.offsetWidth) / 2;
        row.scrollTo({ left: Math.max(0, left), behavior: animate && !IE.reduceMotion() ? 'smooth' : 'auto' });
      });
    }

    function pill(label, isSel, onTap, mark) {
      return h('button', {
        type: 'button', class: ['acct-pill', isSel && 'selected'], 'aria-pressed': String(isSel),
        dataset: mark ? { selected: '1' } : null,
        onclick: onTap,
      }, label);
    }

    function selectedPill(account, sub, onSub) {
      const seg = (key, child, spoken) => h('button', {
        type: 'button', class: sub === key ? 'selected' : null, 'aria-pressed': String(sub === key), 'aria-label': spoken,
        onclick: () => { if (sub !== key) onSub(key); },
      }, child);
      return h('div', { class: 'acct-sel', role: 'group', 'aria-label': 'Sub-account', dataset: { selected: '1' } },
        seg('combined', account.label, 'Combined, ' + account.label),
        seg('cad', IE.currencyFlag('CAD'), 'Canadian dollar holdings'),
        seg('usd', IE.currencyFlag('USD'), 'US dollar holdings'));
    }

    el.update = (next) => {
      const changed = next.selected !== p.selected;
      p = Object.assign(p, next);
      render(changed);
    };
    render(false);
    return el;
  }

  /**
   * "TFSA 12345678 ▾" for a condensed header, once the account pills have
   * scrolled away. Tapping it lists every account (and All) in a sheet.
   */
  function condensedAccountSelector({ accounts, selected, onSelected }) {
    const account = accounts.find((a) => a.name === selected) || null;
    const label = account ? account.label : 'All accounts';
    return h('button', {
      type: 'button', class: 'row condensed-acct', 'aria-label': `${label}, change account`,
      style: 'min-height:44px;padding:0 8px;border-radius:8px;gap:4px;max-width:100%;font:inherit;color:inherit',
      dataset: { testid: 'condensed-account-selector' },
      onclick: async () => {
        const choice = await showSheet((close) => {
          const row = (a) => {
            const isSel = (a ? a.name : null) === selected;
            return h('button', { class: 'list-row', onclick: () => close({ name: a ? a.name : null }), 'aria-pressed': String(isSel) },
              h('div', { class: 'grow' },
                h('div', { class: 't-body-lg', style: 'color:var(--gray-900)' }, a ? a.name : 'All accounts'),
                a ? h('div', { class: 't-body-md-book muted' }, a.numberLine) : null),
              isSel ? icon('check', { color: 'var(--gray-800)' }) : null);
          };
          return h('div', { style: 'padding-bottom:8px' },
            h('h2', { class: 't-heading-xs', style: 'margin:0;padding:0 20px 8px' }, 'Show account'),
            row(null), accounts.map(row));
        }, { label: 'Show account' });
        if (choice && choice.name !== selected) onSelected(choice.name);
      },
    }, h('span', { class: 'ellipsis' }, label), icon('arrow_drop_down', { color: 'var(--gray-800)' }));
  }

  /** A gray-band row with a chevron that opens to show [content]. */
  function expander({ title, content, open = false, titleClass = 't-body-lg-book', padding = '16px 8px', onToggle }) {
    let isOpen = open;
    const chevron = icon('keyboard_arrow_down', { color: 'var(--gray-900)' });
    const panel = h('div', { hidden: !isOpen });
    const head = h('button', { type: 'button', class: 'expander-head', style: { padding }, 'aria-expanded': String(isOpen),
      onclick: () => { isOpen = !isOpen; sync(); onToggle && onToggle(isOpen); } },
    h('span', { class: ['grow', titleClass] }, title), chevron);
    function sync() {
      head.setAttribute('aria-expanded', String(isOpen));
      chevron.textContent = isOpen ? 'keyboard_arrow_up' : 'keyboard_arrow_down';
      panel.hidden = !isOpen;
      if (isOpen && !panel.childNodes.length) IE.append(panel, typeof content === 'function' ? content() : content);
    }
    sync();
    return h('div', { class: 'expander' }, head, panel);
  }

  Object.assign(IE, {
    registerOverlay, showSheet, showDialog, toast, notBuilt, card, sectionHeader, notice, placeholderContent,
    segmented, underlineTabs, pillToggle, rangeSelector, lineChart, showAddAccountSheet,
    SubAccountView, subParam, accountFilter, condensedAccountSelector, expander,
  });
})();
