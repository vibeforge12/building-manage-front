import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:building_manage_front/app/app.dart';

void main() {
  runApp(
    const ProviderScope(
      child: BuildingManageApp(),
    ),
  );
}
