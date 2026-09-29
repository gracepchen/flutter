import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../widgets/motion_animated_size.dart';
import '../../data/mock_portfolio.dart';
import '../../theme/obr_tokens.dart';
import '../../theme/obr_typography.dart';
import '../../util/format.dart';
import '../../widgets/obr_card.dart';
import '../../widgets/obr_segmented_control.dart';

/// Key Stats / News / Events, switched by a segmented control.
class QuoteDetailsTabs extends StatefulWidget {
  const QuoteDetailsTabs({super.key, required this.security});

  final Security security;

  @override
  State<QuoteDetailsTabs> createState() => _QuoteDetailsTabsState();
}

class _QuoteDetailsTabsState extends State<QuoteDetailsTabs> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final security = widget.security;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ObrSegmentedControl(
          labels: const ['Key Stats', 'News', 'Events'],
          selectedIndex: _index,
          onSelected: (i) {
            if (i == _index) return;
            HapticFeedback.selectionClick();
            setState(() => _index = i);
          },
        ),
        const SizedBox(height: ObrSpace.s16),
        MotionAnimatedSize(
          duration: ObrDuration.d250,
          curve: ObrEasing.easeInOut,
          alignment: Alignment.topCenter,
          child: switch (_index) {
            0 => _KeyStats(key: const ValueKey('stats'), security: security),
            1 => _News(key: const ValueKey('news'), security: security),
            _ => _Events(key: const ValueKey('events'), security: security),
          },
        ),
      ],
    );
  }
}

// ─── Key Stats ────────────────────────────────────────────────────────────

class _KeyStats extends StatelessWidget {
  const _KeyStats({super.key, required this.security});

  final Security security;

  @override
  Widget build(BuildContext context) {
    final f = MockResearch.fundamentalsOf(security);
    final eps = MockResearch.epsTtm(security);
    final yieldPercent = MockResearch.dividendYield(security);
    final payout = MockResearch.payoutRatio(security);
    final exDividend = MockResearch.nextExDividend(security);
    final isEtf = security.type == 'ETF';
    const none = '—';
    String percent(double? v) => v == null ? none : '${v.toStringAsFixed(2)}%';

    final stats = <(String, String)>[
      (
        isEtf ? 'Net assets' : 'Market cap',
        NumberFormat.compactCurrency(symbol: r'$', decimalDigits: 1)
            .format(f.marketCap),
      ),
      ('P/E (TTM)', f.peTtm?.toStringAsFixed(2) ?? none),
      ('EPS (TTM)', eps == null ? none : formatCad(eps)),
      ('Beta', f.beta?.toStringAsFixed(2) ?? none),
      ('Currency', security.currency),
      ('Dividend yield', percent(yieldPercent)),
      (
        'Ex-dividend date',
        exDividend == null ? none : DateFormat.yMMMd().format(exDividend),
      ),
      (
        'Annual dividend',
        f.annualDividend > 0 ? formatCad(f.annualDividend) : none,
      ),
      ('Payout ratio', percent(payout)),
      ('Dividend growth (3 yr)', percent(f.dividendGrowth3y)),
    ];

    return Column(
      children: [
        for (var i = 0; i < stats.length; i += 2) ...[
          if (i > 0) const SizedBox(height: ObrSpace.s16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _Stat(stats[i].$1, stats[i].$2)),
              const SizedBox(width: ObrSpace.s16),
              Expanded(
                child: i + 1 < stats.length
                    ? _Stat(stats[i + 1].$1, stats[i + 1].$2)
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: ObrType.bodyMdBook.copyWith(color: ObrColors.gray600),
          ),
          const SizedBox(height: ObrSpace.s2),
          Text(
            value,
            // Screen readers say "not available" rather than "em dash".
            semanticsLabel: value == '—' ? 'Not available' : null,
            style: ObrType.tabular(ObrType.bodyLgSemibold),
          ),
        ],
      ),
    );
  }
}

// ─── News ─────────────────────────────────────────────────────────────────

class _News extends StatelessWidget {
  const _News({super.key, required this.security});

  final Security security;

  static const List<String> _times = ['15 mins ago', '1 hr ago', '3 hrs ago'];

  @override
  Widget build(BuildContext context) {
    // Placeholder copy: headlines, sources and images come from the news feed.
    return Column(
      children: [
        for (var i = 0; i < _times.length; i++) ...[
          if (i > 0) const SizedBox(height: ObrSpace.s12),
          _StoryCard(
            headline: 'Headline placeholder: story ${i + 1} about '
                '${security.name} from the news feed',
            source: '[News provider]',
            time: _times[i],
          ),
        ],
      ],
    );
  }
}

class _StoryCard extends StatelessWidget {
  const _StoryCard({
    required this.headline,
    required this.source,
    required this.time,
  });

  final String headline;
  final String source;
  final String time;

  @override
  Widget build(BuildContext context) {
    final meta = ObrType.bodyMdBook.copyWith(color: ObrColors.gray600);
    return ObrCard(
      padding: EdgeInsets.zero,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(ObrSpace.s20),
                child: MergeSemantics(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(headline, style: ObrType.bodyLgBook),
                      const SizedBox(height: ObrSpace.s8),
                      Text(source, style: meta),
                      Text(time, style: meta),
                    ],
                  ),
                ),
              ),
            ),
            // Image placeholder.
            const ExcludeSemantics(
              child: SizedBox(
                width: 112,
                child: ColoredBox(
                  color: ObrColors.gray100,
                  child: Icon(
                    Icons.image_outlined,
                    color: ObrColors.gray500,
                    size: ObrSize.s32,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Events ───────────────────────────────────────────────────────────────

class _Events extends StatelessWidget {
  const _Events({super.key, required this.security});

  final Security security;

  @override
  Widget build(BuildContext context) {
    final events = MockResearch.eventsOf(security);
    if (events.isEmpty) {
      return Text(
        'No upcoming or recent events for ${security.symbol}.',
        style: ObrType.bodyMdBook.copyWith(color: ObrColors.gray700),
      );
    }

    // Group consecutive events that share a date (the list is newest first).
    final groups = <(DateTime, List<StockEvent>)>[];
    for (final event in events) {
      if (groups.isNotEmpty && groups.last.$1 == event.date) {
        groups.last.$2.add(event);
      } else {
        groups.add((event.date, [event]));
      }
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (date, dayEvents) in groups)
          _EventDay(
            label: date == today
                ? 'Today'
                : date.year == today.year
                    ? DateFormat.MMMd().format(date)
                    : DateFormat.yMMMd().format(date),
            isToday: date == today,
            events: dayEvents,
          ),
      ],
    );
  }
}

class _EventDay extends StatelessWidget {
  const _EventDay({
    required this.label,
    required this.isToday,
    required this.events,
  });

  final String label;
  final bool isToday;
  final List<StockEvent> events;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: ObrSpace.s8),
      padding: const EdgeInsets.all(ObrSpace.s16),
      // Today's events are highlighted, as in the mock.
      decoration: BoxDecoration(
        color: isToday ? ObrColors.gray100 : Colors.transparent,
        borderRadius: BorderRadius.circular(ObrRadius.r16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(label, style: ObrType.headingSubhead),
          ),
          for (final event in events) ...[
            const SizedBox(height: ObrSpace.s12),
            MergeSemantics(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 112,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: _EventTag(
                        label: event.kind == StockEventKind.earnings
                            ? 'Earnings'
                            : 'Ex-dividend',
                      ),
                    ),
                  ),
                  const SizedBox(width: ObrSpace.s12),
                  Expanded(
                    child: Text(event.description, style: ObrType.bodyMdBook),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EventTag extends StatelessWidget {
  const _EventTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ObrColors.gray0,
        borderRadius: BorderRadius.circular(ObrRadius.full),
        border: Border.all(color: ObrColors.gray400),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: ObrSpace.s12,
          vertical: ObrSpace.s4,
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            maxLines: 1,
            style: ObrType.caption.copyWith(color: ObrColors.gray800),
          ),
        ),
      ),
    );
  }
}
