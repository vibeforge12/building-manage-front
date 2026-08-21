import 'package:building_manage_front/core/network/exceptions/api_exception.dart';

/// 예외 객체에서 사용자에게 그대로 보여줄 수 있는 문구를 뽑아낸다.
///
/// - [ApiException]이면 `userFriendlyMessage`
/// - `Exception('...')`이면 `Exception: ` 접두어를 제거한 본문
/// - 그 외에는 [fallback]
///
/// `DioException [...]` 같은 개발자용 원시 문자열이 화면에 노출되지 않도록
/// 사람이 읽을 수 없는 형태는 [fallback]으로 대체한다.
String userMessageOf(
  Object? error, {
  String fallback = '요청을 처리하지 못했습니다. 잠시 후 다시 시도해 주세요.',
}) {
  if (error == null) return fallback;

  if (error is ApiException) return error.userFriendlyMessage;

  final raw = error.toString().trim();
  final message = raw.startsWith('Exception: ')
      ? raw.substring('Exception: '.length).trim()
      : raw;

  if (message.isEmpty) return fallback;

  // 개발자용 예외 문자열은 사용자에게 노출하지 않는다.
  const developerPrefixes = [
    'DioException',
    'ApiException',
    'TypeError',
    'NoSuchMethodError',
    'RangeError',
    'FormatException',
    'StateError',
    '_',
  ];
  for (final prefix in developerPrefixes) {
    if (message.startsWith(prefix)) return fallback;
  }

  return message;
}
