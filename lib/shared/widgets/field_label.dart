import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

Widget fieldLabel(String text, BuildContext? context) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: Theme.of(
        context!,
      ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
    ),
  );
}