import 'package:flutter/material.dart';
import 'package:building_manage_front/features/landing/presentation/screens/main_home_screen.dart';

class BuildingManageApp extends StatelessWidget {
  const BuildingManageApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Building Manage',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF006FFF)),
        useMaterial3: true,
      ),
      home: const MainHomeScreen(),
    );
  }
}
