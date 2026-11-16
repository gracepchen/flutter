// DOM helpers shared by every screen. Everything hangs off the global `IE`
// namespace (plain scripts, no build step, so index.html opens from disk).
window.IE = window.IE || {};

(function () {
  const SVG_NS = 'http://www.w3.org/2000/svg';

  /**
   * h('div', {class: 'card', onclick: fn, style: {...}, aria: {label: 'x'}}, ...children)
   * - class / className: string or array (falsy entries dropped)
   * - style: string or object
   * - on<event>: listener
   * - aria: {label: ...} -> aria-label
   * - dataset: {...}
   * - html: raw innerHTML (trusted, static strings only)
   * - any other key: set as attribute (true -> "", false/null -> omitted)
   * Children: strings, numbers, nodes, arrays (flattened), null/false (skipped).
   */
  function h(tag, props, ...children) {
    const el = document.createElement(tag);
    applyProps(el, props);
    append(el, children);
    return el;
  }

  function s(tag, props, ...children) {
    const el = document.createElementNS(SVG_NS, tag);
    if (props) {
      for (const [k, v] of Object.entries(props)) {
        if (v == null || v === false) continue;
        if (k === 'class') el.setAttribute('class', Array.isArray(v) ? v.filter(Boolean).join(' ') : v);
        else if (k === 'style' && typeof v === 'object') Object.assign(el.style, v);
        else if (k.startsWith('on') && typeof v === 'function') el.addEventListener(k.slice(2), v);
        else el.setAttribute(k, v);
      }
    }
    append(el, children);
    return el;
  }

  function applyProps(el, props) {
    if (!props) return;
    for (const [k, v] of Object.entries(props)) {
      if (v == null || v === false) continue;
      if (k === 'class' || k === 'className') {
        const c = Array.isArray(v) ? v.filter(Boolean).join(' ') : v;
        if (c) el.className = c;
      } else if (k === 'style') {
        if (typeof v === 'string') el.style.cssText = v;
        else for (const [sk, sv] of Object.entries(v)) {
          if (sv == null) continue;
          if (sk.startsWith('--')) el.style.setProperty(sk, sv);
          else el.style[sk] = typeof sv === 'number' && !NO_PX.has(sk) ? sv + 'px' : sv;
        }
      } else if (k === 'aria') {
        for (const [ak, av] of Object.entries(v)) if (av != null) el.setAttribute('aria-' + ak, av);
      } else if (k === 'dataset') {
        Object.assign(el.dataset, v);
      } else if (k === 'html') {
        el.innerHTML = v;
      } else if (k === 'text') {
        el.textContent = v;
      } else if (k.startsWith('on') && typeof v === 'function') {
        el.addEventListener(k.slice(2).toLowerCase(), v);
      } else if (k === 'value' && 'value' in el) {
        el.value = v;
      } else if (k === 'checked' || k === 'disabled' || k === 'hidden' || k === 'selected') {
        el[k] = !!v;
      } else {
        el.setAttribute(k, v === true ? '' : v);
      }
    }
  }

  const NO_PX = new Set(['opacity', 'zIndex', 'flex', 'flexGrow', 'flexShrink', 'fontWeight', 'lineHeight', 'order']);

  function append(el, children) {
    for (const c of children) {
      if (c == null || c === false || c === true) continue;
      if (Array.isArray(c)) append(el, c);
      else if (c instanceof Node) el.appendChild(c);
      else el.appendChild(document.createTextNode(String(c)));
    }
  }

  /** Replaces el's children. */
  function mount(el, ...children) {
    el.textContent = '';
    append(el, children);
    return el;
  }

  // ── Icons ──
  // Material Symbols (Outlined) by ligature name; a few custom glyphs are
  // drawn as SVG to match the Flutter app's painters.
  function icon(name, opts = {}) {
    const size = opts.size || 24;
    if (name === 'move_money') return moveMoneyIcon(size, opts.color);
    const el = h('span', {
      class: ['icon', opts.fill && 'fill', opts.class],
      'aria-hidden': 'true',
      style: { fontSize: size + 'px', color: opts.color || null },
    }, name);
    return el;
  }

  /** Move money: an outlined banknote with "$" and speed lines on the left. */
  function moveMoneyIcon(size = 24, color) {
    const c = color || 'currentColor';
    const sw = 24 * 0.075;
    return s('svg', { class: 'icon-svg', width: size, height: size, viewBox: '0 0 24 24', 'aria-hidden': 'true', style: color ? { color } : null },
      s('rect', { x: 8.64, y: 6.48, width: 14.16, height: 11.04, rx: 1.44, fill: 'none', stroke: c, 'stroke-width': sw }),
      s('text', { x: 15.72, y: 12.1, 'text-anchor': 'middle', 'dominant-baseline': 'central', 'font-size': 8.64, 'font-weight': 700, fill: c, 'font-family': 'Arial, sans-serif' }, '$'),
      s('line', { x1: 2.88, y1: 9.12, x2: 6.24, y2: 9.12, stroke: c, 'stroke-width': 1.68, 'stroke-linecap': 'round' }),
      s('line', { x1: 0.96, y1: 12, x2: 6.24, y2: 12, stroke: c, 'stroke-width': 1.68, 'stroke-linecap': 'round' }),
      s('line', { x1: 2.88, y1: 14.88, x2: 6.24, y2: 14.88, stroke: c, 'stroke-width': 1.68, 'stroke-linecap': 'round' }),
    );
  }

  /** Simplified Canadian or U.S. flag (decorative). */
  function currencyFlag(currency, width = 24) {
    const w = 24, hgt = 16;
    const kids = [s('rect', { x: 0, y: 0, width: w, height: hgt, fill: '#fff' })];
    if (currency === 'USD') {
      const st = hgt / 13;
      for (let i = 0; i < 13; i += 2) kids.push(s('rect', { x: 0, y: i * st, width: w, height: st, fill: '#B22234' }));
      kids.push(s('rect', { x: 0, y: 0, width: w * 0.4, height: st * 7, fill: '#3C3B6E' }));
    } else {
      kids.push(s('rect', { x: 0, y: 0, width: w / 4, height: hgt, fill: '#D52B1E' }));
      kids.push(s('rect', { x: w * 0.75, y: 0, width: w / 4, height: hgt, fill: '#D52B1E' }));
      const cx = w / 2;
      const P = [[cx, .15], [cx + w * .05, .38], [cx + w * .16, .32], [cx + w * .11, .58], [cx + w * .03, .62], [cx + w * .02, .85],
        [cx - w * .02, .85], [cx - w * .03, .62], [cx - w * .11, .58], [cx - w * .16, .32], [cx - w * .05, .38]];
      kids.push(s('polygon', { points: P.map(([x, y]) => `${x},${y * hgt}`).join(' '), fill: '#D52B1E' }));
    }
    kids.push(s('rect', { x: 0.25, y: 0.25, width: w - 0.5, height: hgt - 0.5, fill: 'none', stroke: '#BBBCBC', 'stroke-width': 0.5 }));
    return s('svg', { class: 'flag', width, height: width * 2 / 3, viewBox: `0 0 ${w} ${hgt}`, 'aria-hidden': 'true' }, kids);
  }

  /** The Investor's Edge mark: dark tile with a white rounded diamond ring. */
  function ieMark(size = 128) {
    const side = 100 * 0.73 / Math.SQRT2;
    const hole = side * 0.37;
    return s('svg', { width: size, height: size, viewBox: '0 0 100 100', role: 'img', 'aria-label': "Investor's Edge" },
      s('rect', { x: 0, y: 0, width: 100, height: 100, fill: '#383B3E' }),
      s('g', { transform: 'translate(50 50) rotate(45)' },
        s('path', {
          'fill-rule': 'evenodd', fill: '#fff',
          d: roundedRectPath(-side / 2, -side / 2, side, side, side * 0.07) +
            ` M${-hole / 2} ${-hole / 2} h${hole} v${hole} h${-hole} Z`,
        })));
  }

  function roundedRectPath(x, y, w, hh, r) {
    return `M${x + r} ${y} h${w - 2 * r} a${r} ${r} 0 0 1 ${r} ${r} v${hh - 2 * r} a${r} ${r} 0 0 1 ${-r} ${r} h${-(w - 2 * r)} a${r} ${r} 0 0 1 ${-r} ${-r} v${-(hh - 2 * r)} a${r} ${r} 0 0 1 ${r} ${-r} Z`;
  }

  /** A round icon button with a tooltip / accessible label. */
  function iconButton(name, label, onClick, opts = {}) {
    return h('button', {
      class: ['icon-btn', opts.class],
      type: 'button',
      title: label,
      'aria-label': label,
      onclick: onClick,
      style: opts.style,
    }, icon(name, { size: opts.size || 24, color: opts.color }));
  }

  function reduceMotion() {
    return window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  }

  /** Light haptic tick where the platform supports it. */
  function haptic() {
    try { if (navigator.vibrate) navigator.vibrate(8); } catch (_) { /* ignore */ }
  }

  Object.assign(IE, { h, s, mount, append, icon, moveMoneyIcon, currencyFlag, ieMark, iconButton, reduceMotion, haptic });
})();
