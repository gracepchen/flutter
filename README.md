# Investor's Edge prototype: HTML version

A plain HTML/CSS/JavaScript port of the Flutter prototype in `../investors_edge_prototype`
(same screens, flows, copy and mock data). No build step and no server needed.

## Open it

- Double-click `index.html` (or drag it into Chrome, Safari, Edge or Firefox).
- On a desktop browser it shows in a phone-sized frame; on a phone it fills the screen.
- Open straight to a page with a hash, e.g. `index.html#/holdings?account=TFSA` or
  `index.html#/quote/AAPL` (counts as signed on).
- **Back:** the header's Back button, or the browser's Back button / Android back gesture,
  which acts as the system back (closes a sheet first, asks before signing off on Portfolio).
- Everything is in memory, as in the Flutter app: a reload starts fresh.

`investors_edge_prototype.html` (one level up, if you have it) is the same app bundled into
a single file you can send around.

## What's in it

- Sign On and signing in; Portfolio (Home) with every widget; Holdings; Activity; Move money;
  Search with Markets & Movers; stock/ETF details; Profile with the Nav/IA switcher (C, B, A, D);
  Help; Contact us; eDocuments; Fractional; and all placeholder pages (Trade, Add funds,
  Performance, Watchlists, Contributions, Notifications, Account Settings…).
- Auto-hiding bottom bar and condensing sticky header on Search, Move, Activity, Holdings,
  Watchlists, Performance and Contributions; condensed account selector on Holdings and Activity.
- Back-navigation rules: Back retraces main pages with their account and tab; Portfolio reopens
  the Portfolio subpage last left.

## Layout of the code

- `css/tokens.css`: OBR Design System tokens (colours, type scale, radii, shadows, motion).
- `css/app.css`: shared layout and components; `css/screens/*.css`: per-screen styles.
- `js/core/`: `dom.js` (element helpers, icons, flags, IE mark), `format.js`, `raw_data.js`
  (mock data generated from the Dart file), `data.js` (portfolio, holdings, market, research
  logic), `state.js` (app state, navigation history), `router.js` (GoRouter-style stack),
  `ui.js` (sheets, dialogs, snackbars, shared controls), `chrome.js` (condensing header,
  auto-hide bar), `navbar.js` (the four Nav/IA bottom bars).
- `js/screens/`: one file per screen group; each registers its routes with `IE.route()`.
- `fonts/`: Material Symbols (Apache 2.0), bundled so icons work offline.

## Differences from Flutter

- Charts use a different seeded random generator, so line shapes differ (start and end values
  match).
- Some dropdowns are native `<select>` controls.
- No haptics beyond a light vibration on Android browsers; no app-icon quick actions
  (use `#/search?focus=1` for Quick quote).
