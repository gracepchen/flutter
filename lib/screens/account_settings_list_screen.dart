import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/mock_portfolio.dart';
import '../router.dart';
import '../theme/obr_tokens.dart';
import '../theme/obr_typography.dart';

/// Account Settings, reached from the gear on Holdings when All is selected.
/// "MY ACCOUNTS" lists each account; a row opens that account's settings.
/// "Open an account" and the ⋯ menu aren't built yet.
class AccountSettingsListScreen extends StatelessWidget {
  const AccountSettingsListScreen({super.key});

  void _notBuilt(BuildContext context, String label) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('$label is not built yet in this prototype.')),
      );
  }

  @override
  Widget build(BuildContext context) {
    final accounts = MockPortfolio.accounts;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Settings'),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                ObrSpace.s20,
                ObrSpace.s16,
                ObrSpace.s20,
                ObrSpace.s32,
              ),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: Text(
                          'My accounts'.toUpperCase(),
                          style: ObrType.headingCaption.copyWith(
                            color: ObrColors.gray700,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'More options',
                      onPressed: () => _notBuilt(context, 'More options'),
                      style: IconButton.styleFrom(
                        backgroundColor: ObrColors.gray100,
                      ),
                      icon: const Icon(Icons.more_horiz),
                      color: ObrColors.gray700,
                    ),
                  ],
                ),
                const SizedBox(height: ObrSpace.s12),
                Material(
                  color: ObrColors.gray0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(ObrRadius.r12),
                    side: const BorderSide(color: ObrColors.gray300),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      for (var i = 0; i < accounts.length; i++) ...[
                        if (i > 0)
                          const Divider(
                            height: 1,
                            thickness: 1,
                            indent: ObrSpace.s20,
                            endIndent: ObrSpace.s20,
                            color: ObrColors.gray300,
                          ),
                        _AccountRow(
                          label: '${accounts[i].name} ${accounts[i].number}',
                          onTap: () => context.push(
                            Uri(
                              path: AppRoutes.accountSettings,
                              queryParameters: {'account': accounts[i].name},
                            ).toString(),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: ObrSpace.s40),
                Material(
                  color: ObrColors.gray100,
                  borderRadius: BorderRadius.circular(ObrRadius.r12),
                  clipBehavior: Clip.antiAlias,
                  child: Semantics(
                    button: true,
                    label: 'Open an account',
                    onTap: () => _notBuilt(context, 'Open an account'),
                    excludeSemantics: true,
                    child: InkWell(
                      onTap: () => _notBuilt(context, 'Open an account'),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          minHeight: ObrSize.s72,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: ObrSpace.s20,
                            vertical: ObrSpace.s16,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Open an account',
                                  style: ObrType.bodyLgSemibold.copyWith(
                                    color: ObrColors.gray700,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.add_circle_outline,
                                color: ObrColors.brand600,
                                size: ObrSize.s24,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$label settings',
      onTap: onTap,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: ObrSize.s64),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: ObrSpace.s20,
              vertical: ObrSpace.s16,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: ObrType.bodyLgSemibold.copyWith(
                      color: ObrColors.gray700,
                    ),
                  ),
                ),
                const SizedBox(width: ObrSpace.s12),
                const Icon(
                  Icons.chevron_right,
                  color: ObrColors.brand600,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
