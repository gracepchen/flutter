import 'package:flutter/material.dart';

import '../theme/obr_tokens.dart';
import '../theme/obr_typography.dart';

/// Informational banner (blue ramp) that flags unbuilt prototype areas.
class PrototypeNotice extends StatelessWidget {
  const PrototypeNotice({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ObrColors.blue100,
        borderRadius: BorderRadius.circular(ObrRadius.r12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(ObrSpace.s16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline, color: ObrColors.blue800, size: 20),
            const SizedBox(width: ObrSpace.s12),
            Expanded(
              child: Text(
                message,
                style: ObrType.bodyMdBook.copyWith(color: ObrColors.blue900),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
