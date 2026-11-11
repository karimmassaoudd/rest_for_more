import 'package:flutter/material.dart';

import '../../models/home/home_card.dart';
import 'home_carousel_card.dart';
import '../common/page_dots.dart';

/// Swipeable row of [HomeCard]s with page dots inside each card.
/// One card is shown at a time; the dots can also be tapped.
class HomeCarousel extends StatefulWidget {
  const HomeCarousel({
    super.key,
    required this.cards,
    this.initialIndex = 0,
    this.height = 260,
  });

  final List<HomeCard> cards;

  /// Which card is shown first (e.g. the evening card in the evening).
  final int initialIndex;

  final double height;

  @override
  State<HomeCarousel> createState() => _HomeCarouselState();
}

class _HomeCarouselState extends State<HomeCarousel> {
  late final PageController _controller = PageController(
    initialPage: widget.initialIndex,
  );
  late int _index = widget.initialIndex;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goTo(int i) => _controller.animateToPage(
    i,
    duration: const Duration(milliseconds: 300),
    curve: Curves.easeOut,
  );

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: PageView.builder(
        controller: _controller,
        itemCount: widget.cards.length,
        onPageChanged: (i) => setState(() => _index = i),
        itemBuilder: (context, i) {
          final card = widget.cards[i];
          return Padding(
            // Small gap between cards while swiping.
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: HomeCarouselCard(
              card: card,
              footer: PageDots(
                count: widget.cards.length,
                active: _index,
                color: card.textColor,
                onTap: _goTo,
              ),
            ),
          );
        },
      ),
    );
  }
}
