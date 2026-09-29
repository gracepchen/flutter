# Investor's Edge: native home prototype

A starting point for the native Flutter version of Investor's Edge. It is built on the
**OBR Design System** primitives. It has the portfolio home screen from the mock and
placeholder screens for **Add, Transfer, Trade, Activity and Search**. It also has placeholders for
the other taps on the home screen (such as Profile & Settings), so no tap leads nowhere.

All figures are mock data (`lib/data/mock_portfolio.dart`).

## Run it

This folder holds `lib/`, `test/` and `pubspec.yaml`. Generate the platform folders once:

```bash
cd investors_edge_prototype
flutter create . --platforms=ios,android --org com.yourteam   # won't overwrite lib/ or pubspec.yaml
flutter pub get
flutter run
flutter test
```

Requires Flutter 3.27 or later.

**Launcher icon:** after `flutter create`, generate the iOS and Android app icons from
`assets/icon/` (settings are in `pubspec.yaml`):

```bash
dart run flutter_launcher_icons
```

`app_icon.png` is the full icon (1024×1024): a white rounded diamond ring on dark gray.
`app_icon_foreground.png` is the ring alone for Android's adaptive icon, sized to its safe zone.

**Android predictive back:** after `flutter create`, add
`android:enableOnBackInvokedCallback="true"` to the `<application>` tag in
`android/app/src/main/AndroidManifest.xml`. The theme already uses
`PredictiveBackPageTransitionsBuilder`.

**Whitney font:** the design system export doesn't include the font files. Add the licensed
`.otf` files to `assets/fonts/` and uncomment the `fonts:` block in `pubspec.yaml`. Until then,
text falls back to Arial and then the system font.

## Structure

```
lib/
  main.dart                  edge-to-edge setup, runApp
  app.dart                   MaterialApp.router + OBR theme
  router.dart                go_router routes; AppRoutes constants
  theme/
    obr_tokens.dart          colours, spacing, size, radius, motion, blur, shadow
    obr_typography.dart      display / heading / body / label scales
    obr_theme.dart           tokens mapped onto Material ThemeData
  data/mock_portfolio.dart   accounts, chart series, activity, securities
  util/                      number formatting, reduced-motion helper
  widgets/                   ObrCard, SectionHeader, PrototypeNotice, RangeSelector,
                             SwipeRevealRow, ObrSegmentedControl, PillToggle,
                             FadeSwitcher
  state/                     BalanceVisibility (hide-balances toggle)
  screens/
    home/                    HomeScreen + its sections
    action_screens.dart      Add, Transfer, Trade, Activity, Performance
    profile_screen.dart      Profile & Settings
    account_settings_list_screen.dart  Account Settings (list of accounts)
    search_screen.dart       Search (filters mock securities)
    search/                  Market overview carousel, Find your next move links
    holdings/                Holdings: account filter, cash and Stocks & ETFs accordions
    quote/                   Security details: quote_screen, number_lines,
                             analyst_ratings_card, details_tabs
    placeholder/             shared placeholder layout
    sign_on/                 Sign On and signing-in screens
```

## Sign On

The app opens on **Sign On**: a single gray "Sign on" button on white. Tapping it shows the
signing-in screen (the Investor's Edge mark, `IeMark`, turning slowly clockwise on light gray;
one turn every 4 seconds; still under Reduce Motion) for 900 ms, then goes to Home, replacing the sign-on screens so Back
doesn't return to them. **Sign Off** at the bottom of Profile & Settings returns to Sign On
the same way. Sign-on is simulated. Next step: real authentication (e.g.
`local_auth`) plus a router `redirect` so every route requires a session.

## Nav/IA versions

Profile & Settings has a **Nav/IA Version** switcher (above Sign off) for comparing navigation
schemes. The choice applies app-wide straight away and resets when the app restarts.

- **A: Search only** (default): the three action buttons on Home and the floating search button.
- **B: Search with shortcuts:** a bottom bar with Home, a search bar and Shortcuts. The search
  bar opens a blank search (field focused) and the bar shrinks, animated, to three centred icons
  (Home, Search, Shortcuts). Shortcuts opens a blurred overlay with Move money (Transfer),
  Activity and Trade sliding in.
- **C: Search with actions:** Home, a search bar, Transfers and Activity; on Search it shrinks to
  four icons (Home, Search, Transfers, Activity).
- **D: Tabs:** Home, Explore (blank search), Move (Transfer) and Activity.

Bar icons are dark gray; the selected one sits on a medium-gray disc (a pill in D). The
Shortcuts links line up above the Shortcuts button wherever it is (right edge on Home, centred
on Search), and a close button takes its place. In B–D the bar shows on Home, Search, Transfer and Activity, and the three action buttons on
Home are hidden (the bar carries them). Other pages (stock details, Holdings and so on) open full
screen on top, as in A. On Search (all versions) tapping anywhere that isn't a control puts the keyboard away; tapping
the search field, or in B–D the bottom bar's search icon, brings it back. Opening or closing B's
Shortcuts leaves the keyboard down. Code: `lib/widgets/app_nav_bar.dart`, `lib/state/nav_version.dart`.

## App shortcuts

Long-pressing the app icon shows **Trade, Add funds, My holdings and Quick quote** (iOS Home Screen
quick actions, Android app shortcuts, via the `quick_actions` plugin; see `lib/app_shortcuts.dart`).

- Signed on: the app goes straight to the page (Trade, Add funds, Holdings, or a blank Search
  with the field focused for Quick quote), with Home underneath so Back returns Home.
- Signed out: Sign On first; after the signing-in screen the app opens that page instead of Home.

The session (`AppSession`) is in memory: starting the app counts as signed out, and Sign Off on
Profile signs out. Shortcuts have no icons yet; add images to the iOS asset catalog / Android
drawables and pass their names as `icon` in `ShortcutItem`. After adding the plugin, run
`flutter pub get` and rebuild (a hot restart isn't enough for new native code).

## What's in the home screen

- **Header:** "Investor's Edge" (24pt), the greeting, a bell button that opens a
  Notifications & What's New placeholder, and a person button for Profile & Settings.
- **Portfolio summary (no card):** total value with an eye toggle, a chevron to the
  Performance placeholder, the change for the selected range, an edge-to-edge area chart in
  the stock details colours (thin gray-700 line, gray-400 fill) and the range selector (1D–ALL).
  The eye hides the client's amounts ($••••••) on Home and on Holdings: totals, account and
  cash balances, position values, quantities and dollar changes. Percentages and market data
  stay visible. The setting is app-wide (`BalanceVisibility`) until changed, and resets when
  the app restarts.
- **Quick actions:** Move money (Transfer), Trade and Activity, as white circles with no
  captions. Add funds is still reachable from Financial progress and the cash rows.
- **My accounts / Top holdings card:** a segmented control switches between the two lists. Under
  the list, "Last updated <date>, 11:59pm ET" sits on the left (lined up with the names) and
  "USDCAD=<rate>" on the right (close of the last business day). Below
  the divider are an oval toggle on the left (`PillToggle`; tap anywhere on it and the thumb
  slides across) and an "All holdings" link to the Holdings page on the right. The toggle switches Accounts between Total and Cash only, and Top Holdings
  between Total and Price; each tab remembers its own setting.
  - **Accounts:** TFSA, Non-Registered, RRSP, FHSA and RESP, each with its account number and
    either its total value with today's change or its cash in CAD and USD. Tapping a row opens
    Holdings with that account's pill selected. Swiping a row left (or
    long-pressing it) keeps the type and number and slides in Manage (account settings
    placeholder), Transfer and Trade, each with the account preselected. The three buttons
    are dark gray with 6pt corners.
  - **Top Holdings:** the five largest positions across all accounts (ranked in CAD). Each row
    shows the ticker and shares held, then either market value (Total) or price per share
    (Price) with today's change in $ and %, in the security's own currency (USD for U.S.
    listings, CAD for Canadian; no $ sign, since the currency is shown). Prices update every 2
    seconds (simulated). A row opens that security's details. Swiping left (or long-pressing)
    slides in Buy and Sell, which open Trade.
  - Open rows keep their closed height; the actions sit in a slim gray inset.
  - In both lists, swiping right or tapping the row puts it back, one row is open at a time, and
    screen readers get the row's actions as custom actions (`SwipeRevealRow`).
- **Recent activity:** the latest items (with a Pending status pill), an All / Trades oval
  toggle at the bottom left (Trades shows the three most recent trades) and See all at the bottom
  right.
- **Watchlists:** a blank card after Recent activity with the same header, "See all" link (to a
  Watchlists placeholder) and height. `SizeReporter` measures Recent activity so the two always
  match. Content is TBD.
- **Make investing stress-free:** a swipeable carousel (cards snap one at a time and the next
  one peeks in): Auto-deposit, Reinvest dividends, a "What's an FHSA?" article and Auto invest.
  Not built yet; each shows a short message.
- **Financial progress:** the lifetime total ("You've invested … CAD in all. Nice job!") and a
  full-width bar chart by year. Below a divider: an Invested / Dividends oval toggle
  (`PillToggle`) on the left, as on the accounts/holdings card, and one link on the right.
  - ⊕ at the top right: a bottom sheet over a dark scrim with One-time transfer and Recurring
    deposit, both opening Add funds with the deposit type shown.
  - Invested: the last three years, with this year (to date) in green. Link: Contributions.
  - Dividends: the last two years, this year to date (green) and this year's projection
    (dashed outline). Link: Reinvest (not built yet).
  - Totals are the sum of the bars (projection excluded), so they always agree. Amounts are
    masked when balances are hidden. Years are relative to today.
- **Floating search button:** a dark-gray circle with a search icon at the bottom left. It opens
  the blank search page (recent searches, market overview, ideas) with the field focused and
  the keyboard up. Stock details keeps its search pill in the app bar.

## Search

A blank search shows:

- **Recent searches:** a one-row, horizontally scrolling carousel of outlined pills, each with
  the ticker in bold and its live price in a lighter weight (ticks every 2 seconds, simulated).
  Tapping one opens that security's details. Opening a security from search results puts it
  first (moving it up if it's already there) and drops the oldest, keeping at most five
  (`RecentSearches`, in memory).
- **Market overview:** an endless carousel of cards for the S&P 500, DJIA, NASDAQ, Oil,
  Gold, S&P/TSX 60, VIX and USD/CAD. It scrolls slowly on its own; press and hold to pause briefly,
  or drag either way, and it resumes a few seconds after release. Values tick every 2 seconds
  (simulated). Auto-scroll is off under Reduce Motion or when a screen reader is navigating.
  Tap the carousel to pause it (it stays paused, even after a drag) and tap again to play.
- **Find your next move:** Top 10 traded stocks/ETFs, Commission-free ETFs and Fractional
  stocks/ETFs. Not built yet; each shows a short message.

Widget tests run with Reduce Motion on (see `pumpApp`) so the carousel doesn't keep
`pumpAndSettle` waiting; one test turns it off to check the auto-scroll and hold-to-pause.

## Security details page

Searching and tapping a result, or tapping a recent search, opens `/quote/<SYMBOL>` on top of
Search. The top bar has Back on the left and the price alert bell and watchlist star on the
right. Back (button or gesture) returns to wherever the page was opened from: a blank search with
the field focused, Home, Holdings, Watchlists and so on (Home if opened directly). Scrolling down
swaps the bar for a compact one with the monogram, ticker and live price; scrolling up brings
Back / alerts / watchlist back. It shows:

- A monogram (a stand-in for the logo), ticker and name. U.S.-listed securities (NASDAQ, NYSE)
  show a **Fractional** tag that opens Fractional Stocks/ETFs: All / Stock / ETF tabs, a
  symbol or company search, Exchange, Market Cap and Sector filters with Clear, Sort by Symbol or
  Name, 10 per page with Buy (opens Trade) on each row, and page links with Next (mock list of
  34 securities).
- Price and change, then Bid and Ask. Tapping any of them opens Trade with the security preselected.
  Price, change, bid/ask (with sizes), volume and the day range update in real time (simulated:
  a small move every 2 seconds). The change is measured over the chart's selected range and
  tagged with the same label as the range selector (1D, 5D, 1M…).
- If the client holds the security, an accordion under Bid and Ask shows **Est. gain/loss**
  (from the live price, average cost and an estimated $6.95 commission to sell; an info icon
  opens the explanation in a bottom sheet). Expanding it (animated) shows Last bought (shares,
  date, price) and Average cost (shares held). Amounts are masked when balances are hidden.
  Data: `MockHoldings.costBasis`, which also sets book value on Holdings.
- Below the chart, number lines: the day range (diamond = open, dot = last price), the
  52-week range, then volume against its 3-month average.
- A price chart (162pt, thin gray line) with ranges from 1D to 5Y and an Advanced Chart link
  (placeholder). The chart history itself is static; only the quote above it is live.
- Analyst ratings: a donut of buy / hold / sell with the number of ratings in the centre, the overall consensus (Strong buy, Moderate
  buy, Hold, Moderate sell or Strong sell, from the net of buy and sell) and each percentage.
  ETFs show a note instead.
- Key Stats / News / Events tabs. Key Stats: market cap (net assets for ETFs), P/E and EPS
  (TTM), beta, currency, dividend yield, ex-dividend date, annual dividend, payout ratio and
  3-year dividend growth; EPS, yield and payout are calculated from price, P/E and dividend so
  they agree. News: placeholder story cards. Events: earnings and ex-dividend dates, newest first,
  with today highlighted; dates are relative to today so there are always upcoming and past
  entries.
- A More information accordion.
- A Buy button pinned to the bottom. If the client holds the security
  (`MockPortfolio.sharesHeld`: CM, AAPL, VFV, XEQT and ENB), a Sell button with the number of shares
  held sits beside it. Both open Trade with the side preselected.

Behaviour from the navigation brief that's already here: platform-native page transitions
(predictive back on Android, edge-swipe on iOS), a reduced-motion path for every animation
(`motionDuration`), edge-to-edge insets, bottom-anchored primary navigation, screen-reader
labels on the chart and icon buttons, and deep-linkable routes (`/trade?symbol=XEQT`).

## Holdings

`/holdings`, from "All holdings" on Home. It shows:

- A back button, a centred "Holdings" title and a gear at the top right. With an account
  selected, the gear opens that account's settings. With All selected, it opens Account
  Settings: a MY ACCOUNTS list (each row opens that account's settings), a ⋯ menu and an
  "Open an account" card (both not built yet).
- Account pills: All, then each account's name and number, scrolling sideways. Arriving from
  an account on Home preselects its pill and scrolls it into view. A sticky dashed "+" at the right
  of the row (pills scrolling under it blur and fade) expands, animated, into the full "+ Add
  account" pill at the end of the list. Either opens a bottom sheet over a dark scrim with Link an
  existing account and Open a new account (not built yet). In dropdown mode it's the last item. With 6 or
  more accounts (`AccountFilter.dropdownThreshold`) they collapse into a dropdown.
- Total value (hidden by the same eye toggle as Home) and intraday change for the selection.
- **Cash**, collapsed by default, with total cash in CAD (USD converted at the USDCAD rate).
- **Stocks & ETFs**, expanded by default, with total securities value and today's change, and
  a "Sort by" menu: Portfolio weight % (default), Daily change $, Daily change %, Asset type,
  Ticker, Name, Quantity, Currency, Price, Market value change and Total gain/loss.
- A "Download holdings" link below Stocks & ETFs (not built yet; shows a short message).
- Row designs for both sections are TBD. Placeholder rows show the ticker (or currency) and
  the value for the current sort, so sorting can be reviewed. The mock data doesn't split
  positions by account, so picking an account changes the totals and shows a note, but the
  list still shows every holding.

## Design decisions to confirm

1. **Selected states are dark gray (`gray-700`).** Chart range pills, segmented controls
   (My accounts / Top holdings, Key Stats / News / Events) and oval toggles all use a gray-700
   thumb with white text, so selection reads as neutral and brand red stays for actions.
   Segmented controls are one light-gray track with a thumb that slides between segments.
   Logos, activity icons and promo icons are dark gray on light gray.
2. **Negative values** use `orange-700`, since OBR reserves orange for caution and Sell, and green
   for positive and Buy. Brand red is kept for actions, so losses don't look like buttons.
3. **Semantic component tokens** (button states, Buy/Sell variants) aren't in the design system
   export yet. Components here are built from primitives only.

## Suggested next steps

- Put an auth `redirect` (with `refreshListenable`) on the router, so every route, including
  notification deep links, passes one session and biometric check.
- When there are more top-level destinations, move the dock into a `StatefulShellRoute` so
  each tab keeps its own scroll position and stack.
- At 840dp and up (tablets, unfolded foldables): a navigation rail and a two-pane layout
  (for example, watchlist and quote side by side).
- Replace `MockPortfolio` with a repository and add loading skeletons for balances and quotes.
