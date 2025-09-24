import 'package:flutter_riverpod/flutter_riverpod.dart';

final loadingProvider = StateProvider<bool>((ref) => false);

final errorMessageProvider = StateProvider<String?>((ref) => null);