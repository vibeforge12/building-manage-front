import 'package:flutter/material.dart';

/// Keeps the footer at the bottom when it fits and allows small menus to scroll.
class ScrollableMenuBody extends StatelessWidget {
  const ScrollableMenuBody({
    super.key,
    required this.children,
    this.crossAxisAlignment = CrossAxisAlignment.center,
  });
  final List<Widget> children;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: constraints.maxHeight),
        child: IntrinsicHeight(
          child: Column(
            crossAxisAlignment: crossAxisAlignment,
            children: children,
          ),
        ),
      ),
    ),
  );
}
