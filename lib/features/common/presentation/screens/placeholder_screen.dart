import 'package:flutter/material.dart';

import 'package:building_manage_front/features/common/presentation/widgets/page_header_text.dart';

class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: PageHeaderText(title)),
      body: Center(
        child: Text(
          '$title 화면은 구현 예정입니다.',
          style: Theme.of(context).textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
