import 'package:flutter/material.dart';

import '../../models/home/home_card.dart';
import '../../theme/app_fonts.dart';

/// One card of the Home carousel: icon, small text, title, one button.
/// [footer] is shown under the button (the carousel puts its dots there).
class HomeCarouselCard extends StatelessWidget {
  const HomeCarouselCard({super.key, required this.card, this.footer});

  final HomeCard card;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final border = card.buttonBorder;

    return Container(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 14),
      decoration: BoxDecoration(
        color: card.background,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 25,
            child: Icon(card.icon, size: card.iconSize, color: card.iconColor),
          ),
          const Spacer(),
          Text(
            card.eyebrow,
            style: AppFonts.manrope(size: 12, color: card.textColor),
          ),
          const SizedBox(height: 4),
          Text(
            card.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppFonts.cormorant(
              size: 26,
              weight: FontWeight.w600,
              color: card.textColor,
            ).copyWith(height: 1.1),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: card.onPressed,
              style: FilledButton.styleFrom(
                backgroundColor: card.buttonColor,
                foregroundColor: card.buttonTextColor,
                textStyle: AppFonts.manrope(size: 15, weight: FontWeight.w600),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                  side: border == null
                      ? BorderSide.none
                      : BorderSide(color: border),
                ),
              ),
              child: Text(card.buttonLabel),
            ),
          ),
          if (footer != null) ...[
            const SizedBox(height: 12),
            Center(child: footer),
          ],
        ],
      ),
    );
  }
}
