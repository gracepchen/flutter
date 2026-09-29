import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../router.dart';
import '../../theme/obr_tokens.dart';
import '../../theme/obr_typography.dart';

/// Sign On: a single "Sign on" button on white. Sign-on is simulated:
/// tapping it shows the signing-in screen, then Home.
class SignOnScreen extends StatelessWidget {
  const SignOnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: ObrColors.gray0,
        body: Center(
          child: Semantics(
            button: true,
            label: 'Sign on',
            excludeSemantics: true,
            child: FilledButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                context.go(AppRoutes.signingIn);
              },
              style: FilledButton.styleFrom(
                backgroundColor: ObrColors.gray600,
                foregroundColor: ObrColors.gray0,
                minimumSize: const Size(130, ObrSize.s48),
                padding: const EdgeInsets.symmetric(horizontal: ObrSpace.s32),
                textStyle: ObrType.headingXs.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(ObrRadius.r8),
                ),
              ),
              child: const Text('Sign on'),
            ),
          ),
        ),
      ),
    );
  }
}
