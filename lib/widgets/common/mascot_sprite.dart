import 'package:flutter/material.dart';

class SheepScreen extends StatefulWidget {
  const SheepScreen({super.key});

  @override
  State<SheepScreen> createState() => _SheepScreenState();
}

class _SheepScreenState extends State<SheepScreen> {
  int cell = 6;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sheep')),
      body: Center(
        child: GestureDetector(
          onTap: () => setState(() => cell = (cell + 1) % 9),
          child: MascotSprite(
            sheet: 'assets/mascot/sheep-reactions.webp',
            cell: cell,
          ),
        ),
      ),
    );
  }
}

class MascotSprite extends StatelessWidget {
  const MascotSprite({
    super.key,
    required this.sheet,
    required this.cell,
    this.size = 140,
  });
  final String sheet;
  final int cell; // 0–8, counted row by row
  final double size;

  @override
  Widget build(BuildContext context) {
    final col = cell % 3, row = cell ~/ 3;
    return SizedBox.square(
      dimension: size,
      child: ClipRect(
        child: OverflowBox(
          maxWidth: size * 3,
          maxHeight: size * 3,
          alignment: Alignment(col - 1.0, row - 1.0),
          child: Image.asset(
            sheet,
            width: size * 3,
            height: size * 3,
            fit: BoxFit.fill,
          ),
        ),
      ),
    );
  }
}
