import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../theme/obr_tokens.dart';
import '../../theme/obr_typography.dart';
import '../../util/format.dart';

/// A market index, commodity or currency pair shown in Market Overview.
class MarketInstrument {
  const MarketInstrument({
    required this.name,
    required this.previousClose,
    required this.startValue,
    this.decimals = 2,
  });

  final String name;
  final double previousClose;
  final double startValue;

  /// 4 for currency pairs, 2 otherwise.
  final int decimals;
}

/// Made-up levels for the prototype. USD/CAD starts at the same rate shown
/// on Home.
const List<MarketInstrument> marketInstruments = [
  MarketInstrument(name: 'S&P 500', previousClose: 6745.18, startValue: 6712.40),
  MarketInstrument(name: 'DJIA', previousClose: 46388.02, startValue: 46210.55),
  MarketInstrument(name: 'NASDAQ', previousClose: 22960.71, startValue: 22815.30),
  MarketInstrument(name: 'Oil', previousClose: 70.88, startValue: 71.42),
  MarketInstrument(name: 'Gold', previousClose: 3762.10, startValue: 3785.60),
  MarketInstrument(name: 'S&P/TSX 60', previousClose: 1705.20, startValue: 1712.84),
  MarketInstrument(name: 'VIX', previousClose: 15.92, startValue: 16.84),
  MarketInstrument(
    name: 'USD/CAD',
    previousClose: 1.39870,
    startValue: 1.40123,
    decimals: 4,
  ),
];

/// Infinite, slowly auto-scrolling carousel of market cards whose values tick
/// in real time (simulated).
///
/// - Tap to pause; tap again to play. While paused it never starts again on
///   its own.
/// - While playing, press and hold pauses it and it resumes a few seconds
///   after the finger lifts. Drag to scroll in either direction.
/// - Auto-scroll is off when Reduce Motion is on or a screen reader is
///   navigating, so moving content never fights assistive tech. Cards can
///   still be dragged, and values still update.
class MarketOverviewCarousel extends StatefulWidget {
  const MarketOverviewCarousel({super.key});

  /// Whether auto-scroll can run at all here (not under Reduce Motion or
  /// while a screen reader is navigating).
  static bool autoScrollAllowed(BuildContext context) =>
      !MediaQuery.disableAnimationsOf(context) &&
      !MediaQuery.accessibleNavigationOf(context);

  /// Auto-scroll speed in logical pixels per second.
  static const double speed = 24;

  /// How often values update.
  static const Duration tick = Duration(seconds: 2);

  @override
  State<MarketOverviewCarousel> createState() => _MarketOverviewCarouselState();
}

class _MarketOverviewCarouselState extends State<MarketOverviewCarousel>
    with SingleTickerProviderStateMixin {
  static const double _cardWidth = 184;
  static const double _gap = ObrSpace.s12;
  static const double _extent = _cardWidth + _gap;
  static const Duration _resumeDelay = Duration(seconds: 3);

  // Start far from zero so the carousel can scroll left as well as right.
  late final ScrollController _controller = ScrollController(
    initialScrollOffset: _extent * marketInstruments.length * 1000,
  );
  late final Ticker _ticker = createTicker(_onTick);
  final Random _random = Random(7);
  late final List<double> _values = [
    for (final m in marketInstruments) m.startValue,
  ];

  Timer? _updates;
  Timer? _resume;
  Duration _lastTick = Duration.zero;
  bool _held = false;

  /// Paused by a tap: stays stopped (values keep updating, cards can still
  /// be dragged) until tapped again.
  bool _paused = false;

  /// Time since the finger went down, so a press-and-hold (a temporary
  /// pause) isn't also taken as a tap.
  final Stopwatch _pressed = Stopwatch();

  /// A quick tap toggles pause; a long press only holds.
  void _onTap() {
    if (_pressed.elapsed > const Duration(milliseconds: 400)) return;
    _togglePaused();
  }

  void _togglePaused() {
    _resume?.cancel();
    setState(() {
      _paused = !_paused;
      // Playing again starts straight away, not after the hold delay.
      if (!_paused) _held = false;
    });
    _syncAutoScroll();
  }

  @override
  void initState() {
    super.initState();
    _updates = Timer.periodic(MarketOverviewCarousel.tick, (_) => _updateValues());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAutoScroll();
  }

  void _syncAutoScroll() {
    final shouldRun = MarketOverviewCarousel.autoScrollAllowed(context) &&
        !_held &&
        !_paused;
    if (shouldRun && !_ticker.isActive) {
      _lastTick = Duration.zero;
      _ticker.start();
    } else if (!shouldRun && _ticker.isActive) {
      _ticker.stop();
    }
  }

  void _onTick(Duration elapsed) {
    final dt = (elapsed - _lastTick).inMicroseconds / 1e6;
    _lastTick = elapsed;
    if (!_controller.hasClients || dt <= 0) return;
    _controller.jumpTo(
      _controller.offset + MarketOverviewCarousel.speed * dt,
    );
  }

  void _updateValues() {
    if (!mounted) return;
    setState(() {
      for (var i = 0; i < _values.length; i++) {
        // Small random move, up to ±0.04% per tick.
        final move = (_random.nextDouble() - 0.5) * 0.0008;
        _values[i] = _values[i] * (1 + move);
      }
    });
  }

  void _hold() {
    _pressed
      ..reset()
      ..start();
    _resume?.cancel();
    _held = true;
    _syncAutoScroll();
  }

  void _release() {
    _resume?.cancel();
    _resume = Timer(_resumeDelay, () {
      if (!mounted) return;
      _held = false;
      _syncAutoScroll();
    });
  }

  @override
  void dispose() {
    _updates?.cancel();
    _resume?.cancel();
    _ticker.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canScroll = MarketOverviewCarousel.autoScrollAllowed(context);
    return Semantics(
      // Screen readers get the same pause/play as a tap (only offered when
      // auto-scroll can run).
      onTap: canScroll ? _togglePaused : null,
      onTapHint: canScroll
          ? (_paused ? 'play scrolling' : 'pause scrolling')
          : null,
      child: GestureDetector(
        // Loses to horizontal drags, so dragging still scrolls.
        onTap: canScroll ? _onTap : null,
        child: Listener(
      onPointerDown: (_) => _hold(),
      onPointerUp: (_) => _release(),
      onPointerCancel: (_) => _release(),
      child: NotificationListener<ScrollNotification>(
        // A fling keeps moving after the finger lifts; restart the resume
        // countdown when it settles.
        onNotification: (notification) {
          if (notification is ScrollEndNotification && _held) _release();
          return false;
        },
        child: SizedBox(
          height: 92,
          child: ListView.builder(
            controller: _controller,
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemExtent: _extent,
            // No itemCount: the list is endless and wraps the instruments.
            itemBuilder: (context, index) {
              final i = index % marketInstruments.length;
              return Padding(
                padding: const EdgeInsets.only(right: _gap),
                child: _MarketCard(
                  instrument: marketInstruments[i],
                  value: _values[i],
                ),
              );
            },
          ),
        ),
      ),
        ),
      ),
    );
  }
}

class _MarketCard extends StatelessWidget {
  const _MarketCard({required this.instrument, required this.value});

  final MarketInstrument instrument;
  final double value;

  String _format(double v) => instrument.decimals == 2
      ? formatPrice(v)
      : v.toStringAsFixed(instrument.decimals);

  @override
  Widget build(BuildContext context) {
    final change = value - instrument.previousClose;
    final percent = change / instrument.previousClose * 100;
    final isUp = change >= 0;
    // Market overview: green for gains, dark red (brand-700) for declines.
    final color = isUp ? ObrColors.green600 : ObrColors.brand700;

    return Semantics(
      label: '${instrument.name} ${_format(value)}, '
          '${isUp ? 'up' : 'down'} ${percent.abs().toStringAsFixed(2)} percent',
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: ObrColors.gray0,
          borderRadius: BorderRadius.circular(ObrRadius.r16),
          border: Border.all(color: ObrColors.gray200),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: ObrSpace.s16,
            vertical: ObrSpace.s12,
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: 184 - ObrSpace.s16 * 2 - 2,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Expanded(
                        child: Text(
                          instrument.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: ObrType.bodyLgSemibold,
                        ),
                      ),
                      const SizedBox(width: ObrSpace.s8),
                      Text(
                        _format(value),
                        style: ObrType.tabular(ObrType.bodyMdBook).copyWith(
                          color: ObrColors.gray600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: ObrSpace.s8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        isUp ? Icons.arrow_upward : Icons.arrow_downward,
                        size: ObrSize.s20,
                        color: color,
                      ),
                      const SizedBox(width: ObrSpace.s2),
                      Expanded(
                        child: Text(
                          '${percent.abs().toStringAsFixed(2)}%',
                          style: ObrType.tabular(ObrType.headingSmSemibold)
                              .copyWith(color: color),
                        ),
                      ),
                      Text(
                        _format(change.abs()),
                        style: ObrType.tabular(ObrType.bodyMdBook).copyWith(
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
