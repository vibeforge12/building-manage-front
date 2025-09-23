import 'package:flutter/material.dart';

class PageHeaderText extends StatelessWidget {
  const PageHeaderText(
    this.text, {
    super.key,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  final String text;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  static const _headerColor = Color(0xFF464A4D);

  @override
  Widget build(BuildContext context) {
    final baseStyle =
        Theme.of(context).textTheme.titleMedium ?? const TextStyle();
    return Text(
      text,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      style: baseStyle.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: _headerColor,
      ),
    );
  }
}
