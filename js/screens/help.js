// Help and Contact us (lib/screens/help/help_screen.dart,
// contact_us_screen.dart). Black and white for now; header is Back and the
// centred title only; no bottom bar.
(function () {
  const { h, icon, mount } = IE;

  const TOP_QUESTIONS = [
    'What accounts are available for cash transfers?',
    "What is delisted/defunct security? How to remove them from my Investor's Edge account?",
    'Exchange Agreements',
    "How can I open a CIBC Investor's Edge account?",
    'How do I close an account?',
    "How do I transfer an account from another financial institution to CIBC Investor's Edge?",
    "How do I link a bank account to my Investor's Edge account?",
    'How do I change my address and other contact information?',
    'How do I place a stock or ETF trade?',
    "Where can I find CIBC Investor's Edge forms and applications?",
  ];

  const outlined = (label, onClick) => h('button', { type: 'button', class: 'btn outlined block help-btn', onclick: onClick }, label);
  const filled = (label, onClick) => h('button', { type: 'button', class: 'btn black block help-btn', onclick: onClick }, label);

  // ── Help ──
  IE.route('/help', (params, ctx) => {
    const input = h('input', { class: 'help-field', type: 'text', placeholder: 'Your question', 'aria-label': 'Your question',
      enterkeyhint: 'send', onkeydown: (e) => { if (e.key === 'Enter') ask(); } });
    function ask() {
      input.blur();
      if (!input.value.trim()) { IE.toast('Enter your question first.'); return; }
      IE.notBuilt('Answering questions');
    }

    let open = true;
    const chevron = icon('keyboard_arrow_up', { color: 'var(--gray-800)' });
    const list = h('ol', { class: 'help-questions' }, TOP_QUESTIONS.map((q, i) => h('li', null,
      h('button', { type: 'button', class: 'help-q', 'aria-label': `${i + 1}. ${q}`, onclick: () => IE.notBuilt('This answer') },
        h('span', { class: 'help-q-num' }, `${i + 1}.`), h('span', { class: 'help-q-text' }, q)))));
    const toggle = h('button', { type: 'button', class: 'help-top-head', 'aria-expanded': 'true', onclick: () => {
      open = !open;
      list.hidden = !open;
      chevron.textContent = open ? 'keyboard_arrow_up' : 'keyboard_arrow_down';
      toggle.setAttribute('aria-expanded', String(open));
    } }, h('span', { class: 'grow t-body-lg', style: 'color:var(--gray-800);text-align:left' }, 'Top 10 questions'), chevron);

    const body = h('div', { class: 'content help-content' },
      h('h1', { class: 't-heading-lg center', style: 'margin:0;color:var(--gray-700)' }, 'Have a question?'),
      h('p', { class: 't-body-md-book center muted', style: 'margin:12px 0 0' }, 'Enter your complete question. Do not include any confidential information.'),
      h('div', { class: 'help-ask' }, input, h('button', { type: 'button', class: 'help-ask-btn', onclick: ask }, 'Ask')),
      h('hr', { class: 'divider', style: 'margin-top:24px' }),
      toggle, list,
      h('hr', { class: 'divider' }),
      h('h2', { class: 't-heading-xs center', style: 'margin:40px 0 20px;color:var(--gray-800);font-weight:500' }, 'Can’t find what you’re looking for?'),
      outlined('Contact us', () => IE.router.push(IE.routes.contactUs)));

    return IE.chromePage(ctx, { title: 'Help', body }).el;
  });

  // ── Contact us ──
  const LINES = [
    ['Toll-free for Costco members', '1-877-526-7331', 'Monday to Friday, 8:00 am to 8:00 pm ET', null],
    ['Greater Toronto area', '416-980-3343', 'Monday to Friday, 8:00 am to 8:00 pm ET', null],
    ['Asian trading services', '1-888-366-6888', 'Monday to Friday, 8:30 am to 6:00 pm ET', '(中文热线)'],
  ];
  const FAQS = [
    'How do I fund my account?',
    'How do I submit a cash transfer?',
    "How do I attach a new bank account to my CIBC Investor's Edge account?",
    'How do I change my user ID?',
  ];

  const tbd = (what) => h('p', { class: 't-body-md-book muted', style: 'margin:0' }, `${what}: content TBD in this prototype.`);

  /** A row that opens to show [content]: chevron on the right, or a plus on the left on a gray band. */
  function expandable(title, content, { plus = false, filled: band = false } = {}) {
    let isOpen = false;
    const glyph = icon(plus ? 'add' : 'keyboard_arrow_down', { size: plus ? 20 : 24, color: 'var(--gray-900)' });
    const panel = h('div', { class: 'contact-exp-panel', hidden: true }, content);
    const head = h('button', { type: 'button', class: ['contact-exp-head', band && 'band'], 'aria-expanded': 'false', onclick: () => {
      isOpen = !isOpen;
      panel.hidden = !isOpen;
      glyph.textContent = plus ? (isOpen ? 'remove' : 'add') : (isOpen ? 'keyboard_arrow_up' : 'keyboard_arrow_down');
      head.setAttribute('aria-expanded', String(isOpen));
    } },
    plus ? glyph : null,
    h('span', { class: 'grow t-body-lg-book', style: 'color:var(--gray-900);text-align:left' }, title),
    plus ? null : glyph);
    return h('div', { class: ['contact-exp', band && 'band'] }, head, panel);
  }

  function promptCard(ic, title, text, button, onPress) {
    return h('div', { class: 'contact-card' },
      h('div', { class: 'contact-circle' }, icon(ic, { color: 'var(--gray-900)' })),
      h('h2', { class: 't-body-lg semibold center', style: 'margin:16px 0 0;color:var(--gray-900)' }, title),
      h('p', { class: 't-body-md-book center muted', style: 'margin:12px 0 20px' }, text),
      filled(button, onPress));
  }

  IE.route('/contact-us', (params, ctx) => {
    const chat = () => IE.notBuilt('Chat');
    let option = 'call';
    const optionsBody = h('div');
    const optionsCard = h('div', { class: 'contact-card left' });

    function backToOptions() {
      optionsCard.scrollIntoView({ behavior: IE.reduceMotion() ? 'auto' : 'smooth', block: 'start' });
    }

    function renderOptions() {
      const select = h('select', { class: 'contact-select', 'aria-label': 'Contact options', onchange: (e) => { option = e.target.value; renderOptions(); } },
        h('option', { value: 'call', selected: option === 'call' }, 'Call us'),
        h('option', { value: 'chat', selected: option === 'chat' }, 'Chat with us'));
      mount(optionsCard,
        h('label', { class: 'contact-opt-label' }, 'Contact options'),
        select,
        h('div', { style: 'height:20px' }),
        option === 'chat' ? [
          h('p', { class: 't-body-md-book center muted', style: 'margin:0 0 16px' }, 'Chat with one of our live agents, Monday to Friday, 9:00 am to 5:00 pm ET.'),
          filled('Chat with Us', chat),
        ] : [
          h('h3', { class: 't-body-lg semibold center', style: 'margin:0;color:var(--gray-900)' }, 'Stay connected with us even when you\'re offline'),
          h('div', { class: 'contact-info' }, 'Make sure to have your account number and user ID ready when you call us - it helps us identify you quicker.'),
          LINES.map(([title, phone, hours, note]) => h('div', { class: 'contact-line' },
            h('div', { class: 't-body-lg', style: 'color:var(--gray-900)' }, title),
            note ? h('div', { class: 't-body-md-book', style: 'color:var(--gray-800)' }, note) : null,
            h('button', { type: 'button', class: 'contact-phone', 'aria-label': `Call ${phone}`, onclick: () => IE.notBuilt('Calling') },
              icon('call', { size: 20, color: 'var(--gray-900)' }), h('span', { class: 't-heading-xs', style: 'color:var(--gray-900)' }, phone)),
            h('div', { class: 't-body-md-book muted' }, hours))),
          h('div', { style: 'height:16px' }),
          expandable('Statutory holiday hours', tbd('Statutory holiday hours')),
        ],
        h('div', { class: 'center', style: 'margin-top:16px' },
          h('button', { type: 'button', class: 'contact-return', onclick: backToOptions },
            h('span', null, 'Return to contact options'), icon('keyboard_arrow_up', { size: 20, color: 'var(--gray-700)' }))));
    }
    renderOptions();

    const body = h('div', { class: 'content contact-content' },
      promptCard('lightbulb', 'Need some help?', 'Get instant answers to some of the most popular questions.', 'Ask a question', () => {
        // Help is underneath when Contact us was opened from it.
        const stack = IE.router.stack;
        if (stack.length > 1 && IE.pathOf(stack[stack.length - 2]) === IE.routes.help) IE.router.pop();
        else IE.router.push(IE.routes.help);
      }),
      promptCard('forum', 'Want to chat?', 'For a more personalized touch, ask one of our live agents, Monday to Friday, 9:00 am to 5:00 pm ET.', 'Chat with Us', chat),
      h('div', { class: 'contact-card left' },
        h('h2', { class: 't-body-lg semibold center', style: 'margin:0 0 8px;color:var(--gray-900)' }, 'Frequently asked questions'),
        FAQS.map((q, i) => [i > 0 ? h('hr', { class: 'divider' }) : null, expandable(q, tbd('This answer'))]),
        h('div', { style: 'height:8px' }),
        outlined('Visit FAQ', () => IE.notBuilt('The FAQ page'))),
      optionsCard,
      expandable('Legal disclaimers', tbd('Legal disclaimers'), { plus: true, filled: true }));

    return IE.chromePage(ctx, { title: 'Contact us', body }).el;
  });
})();
