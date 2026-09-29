import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/mock_portfolio.dart';
import '../router.dart';
import '../state/app_session.dart';
import '../state/nav_version.dart';
import '../theme/obr_tokens.dart';
import '../theme/obr_typography.dart';
import 'placeholder/placeholder_screen.dart';

/// Placeholder for Profile & Settings, opened from the person icon on Home.
/// Sign Off at the bottom returns to Sign On.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PlaceholderScreen(
      title: 'Profile & Settings',
      initials: MockPortfolio.initials,
      summary: 'Your personal details and app settings, plus documents, '
          'support and a way back to CIBC Banking.',
      plannedItems: const [
        'Name: ${MockPortfolio.firstName}\'s name and client details',
        'Account Settings: personal information, security (biometrics and '
            '2-step verification) and notifications',
        'eDocuments: statements, trade confirmations and tax slips',
        'Help: answers to common questions',
        'Contact Us: phone, secure message and hours',
        'Share Feedback: tell us about the app',
        'Go to CIBC Banking: switch to the CIBC Mobile Banking app',
      ],
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: ObrSpace.s16),
          const _NavVersionSwitcher(),
          const SizedBox(height: ObrSpace.s48),
          Center(
            child: _OutlineButton(
              label: 'Sign off',
              onPressed: () {
                // `go` replaces the whole stack, so Back can't return to the
                // app. Next step: clear the session and cached data here too.
                AppSessionScope.read(context).signOut();
                context.go(AppRoutes.signOn);
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// "Nav/IA Version": one button per navigation scheme; the selected one is
/// filled. The choice applies app-wide straight away.
class _NavVersionSwitcher extends StatelessWidget {
  const _NavVersionSwitcher();

  @override
  Widget build(BuildContext context) {
    final notifier = NavVersionScope.of(context);
    return Column(
      children: [
        Semantics(
          header: true,
          child: Text('Nav/IA Version', style: ObrType.headingXs),
        ),
        const SizedBox(height: ObrSpace.s16),
        for (final version in NavVersion.values) ...[
          Semantics(
            inMutuallyExclusiveGroup: true,
            selected: version == notifier.value,
            child: version == notifier.value
                ? _FilledButton(
                    label: '${version.letter}: ${version.label}',
                    onPressed: () {},
                  )
                : _OutlineButton(
                    label: '${version.letter}: ${version.label}',
                    onPressed: () => notifier.value = version,
                  ),
          ),
          const SizedBox(height: ObrSpace.s12),
        ],
      ],
    );
  }
}

class _FilledButton extends StatelessWidget {
  const _FilledButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: ObrColors.brand800,
        foregroundColor: ObrColors.gray0,
        minimumSize: const Size(140, ObrSize.s48),
        padding: const EdgeInsets.symmetric(horizontal: ObrSpace.s24),
        textStyle: ObrType.bodyLg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ObrRadius.r4),
        ),
      ),
      child: Text(label),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  const _OutlineButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: ObrColors.brand700,
        minimumSize: const Size(140, ObrSize.s48),
        padding: const EdgeInsets.symmetric(horizontal: ObrSpace.s24),
        side: const BorderSide(color: ObrColors.brand700),
        textStyle: ObrType.bodyLg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ObrRadius.r4),
        ),
      ),
      child: Text(label),
    );
  }
}
