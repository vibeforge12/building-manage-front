import 'dart:io';
import 'dart:ui' as ui;
import 'package:building_manage_front/core/config/app_config.dart';
import 'package:building_manage_front/core/constants/user_types.dart';
import 'package:building_manage_front/core/network/api_client.dart';
import 'package:building_manage_front/core/network/exceptions/api_exception.dart';
import 'package:building_manage_front/domain/entities/user.dart';
import 'package:building_manage_front/modules/auth/presentation/providers/auth_state_provider.dart';
import 'package:building_manage_front/modules/admin/presentation/screens/bulletin_create_screen.dart';
import 'package:building_manage_front/modules/life_service/presentation/providers/life_service_providers.dart';
import 'package:building_manage_front/modules/life_service/presentation/screens/life_service_form_screen.dart';
import 'package:building_manage_front/modules/life_service/presentation/screens/life_service_detail_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  setUpAll(() async {
    dotenv.testLoad(fileInput: 'API_BASE_URL=http://localhost:3002');
    if (Platform.environment['DESIGN_CAPTURE'] == '1') {
      final icons = FontLoader('MaterialIcons')
        ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await icons.load();
      final font = File('/System/Library/Fonts/Supplemental/Arial Unicode.ttf');
      if (font.existsSync()) {
        final loader = FontLoader('Pretendard')
          ..addFont(
            Future.value(ByteData.sublistView(await font.readAsBytes())),
          );
        await loader.load();
      }
    }
  });

  testWidgets('사진은 최대 5장까지만 선택하고 제거할 수 있다', (tester) async {
    final picker = _Picker(List.generate(6, (i) => _Photo('photo$i.png')));
    await _pump(tester, _Api(), const LifeServiceFormScreen(), picker: picker);
    await tester.tap(find.byTooltip('사진 첨부 (최대 5장)'));
    await tester.pumpAndSettle();
    expect(find.text('사진 5 / 5'), findsOneWidget);
    expect(picker.fullMetadata, isFalse);
    await tester.tap(find.byIcon(Icons.close).first);
    await tester.pumpAndSettle();
    expect(find.text('사진 4 / 5'), findsOneWidget);
  });

  testWidgets('선택 후 임시 파일이 없어져도 저장·재시도는 파일을 다시 읽거나 업로드하지 않는다', (tester) async {
    final api = _Api()..failSave = true;
    await _pump(
      tester,
      api,
      const LifeServiceFormScreen(),
      picker: _Picker([_Photo('photo.png')]),
    );
    await tester.enterText(find.byType(TextFormField).at(0), '사진 서비스');
    await tester.enterText(find.byType(TextFormField).at(1), '안내 내용');
    await tester.tap(find.byTooltip('사진 첨부 (최대 5장)'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '신청 열기'));
    await tester.pumpAndSettle();
    expect(api.uploads, 1);
    expect(api.lastSave!['imageKeys'], ['uploaded-key']);
    expect(find.text('테스트 저장 실패'), findsOneWidget);
    api.failSave = false;
    await tester.tap(find.text('확인').last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '신청 열기'));
    await tester.pumpAndSettle();
    expect(api.uploads, 1);
    expect(find.text('저장 완료'), findsOneWidget);
  });

  testWidgets('수정 시 기존 사진은 유지되며 제거한 사진만 제외된다', (tester) async {
    final api = _Api()
      ..keys = ['existing-key']
      ..urls = ['https://example.invalid/image.png'];
    await _pump(tester, api, const LifeServiceFormScreen(lifeServiceId: 'one'));
    expect(find.text('사진 1 / 5'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, '수정 완료'));
    await tester.pumpAndSettle();
    expect(api.lastSave!['imageKeys'], ['existing-key']);
    expect(api.uploads, 0);
    await _pump(tester, api, const LifeServiceFormScreen(lifeServiceId: 'one'));
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '수정 완료'));
    await tester.pumpAndSettle();
    expect(api.lastSave!['imageKeys'], isEmpty);
  });

  testWidgets('사진 읽기 실패는 내부 파일 경로를 노출하지 않는다', (tester) async {
    await _pump(
      tester,
      _Api(),
      const LifeServiceFormScreen(),
      picker: _Picker([_BrokenPhoto('missing.png')]),
    );
    await tester.tap(find.byTooltip('사진 첨부 (최대 5장)'));
    await tester.pumpAndSettle();
    expect(find.text('사진 첨부 실패'), findsOneWidget);
    expect(find.textContaining('/private/secret'), findsNothing);
  });

  testWidgets('Dev 사진 상대 경로는 현재 API 호스트를 사용한다', (tester) async {
    final api = _Api()
      ..keys = ['key']
      ..urls = [
        '/api/v1/life-service-images/building/photo.png?signature=test',
      ];
    await _pump(tester, api, const LifeServiceFormScreen());
    final container = ProviderScope.containerOf(
      tester.element(find.byType(LifeServiceFormScreen)),
    );
    final item = await container
        .read(lifeServiceUseCasesProvider)
        .detail('one');
    expect(item.imageUrls.single, startsWith(AppConfig.baseUrl));
    expect(item.imageKeys, ['key']);
    expect(
      () => container
          .read(lifeServiceUseCasesProvider)
          .uploadImage(Uint8List(0), 'empty.png'),
      throwsA(isA<ApiException>()),
    );
  });

  for (final width in [320.0, 390.0, 768.0]) {
    for (final entry in <String, Widget>{
      'reference': const BulletinCreateScreen(),
      'service-form': const LifeServiceFormScreen(),
      'service-detail': const LifeServiceDetailScreen(lifeServiceId: 'one'),
    }.entries) {
      testWidgets('${entry.key} ${width.toInt()}px 기존 디자인·줄넘침 확인', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await _pump(tester, _Api(), entry.value, scale: width == 320 ? 1.3 : 1);
        expect(tester.takeException(), isNull);
        if (Platform.environment['DESIGN_CAPTURE'] == '1') {
          await tester.runAsync(() async {
            final boundary = tester.renderObject<RenderRepaintBoundary>(
              find.byKey(const ValueKey('capture')),
            );
            final image = await boundary.toImage(pixelRatio: 1);
            final png = await image.toByteData(format: ui.ImageByteFormat.png);
            final out = File(
              'build/design-service/${entry.key}-${width.toInt()}.png',
            );
            await out.parent.create(recursive: true);
            await out.writeAsBytes(png!.buffer.asUint8List());
            image.dispose();
          });
        }
      });
    }
  }
}

Future<void> _pump(
  WidgetTester tester,
  _Api api,
  Widget screen, {
  _Picker? picker,
  double scale = 1,
}) async {
  await tester.pumpWidget(const SizedBox.shrink());
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const Scaffold(body: Text('저장 완료')),
      ),
      GoRoute(path: '/form', builder: (_, __) => screen),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        apiClientProvider.overrideWithValue(api),
        lifeServiceImagePickerProvider.overrideWithValue(picker ?? _Picker([])),
        currentUserProvider.overrideWithValue(
          const User(
            id: 'staff',
            email: '',
            name: '담당자',
            userType: UserType.manager,
            buildingName: '로컬 테스트 건물',
          ),
        ),
      ],
      child: RepaintBoundary(
        key: const ValueKey('capture'),
        child: MaterialApp.router(
          routerConfig: router,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  router.push('/form');
  await tester.pumpAndSettle();
}

class _Photo extends XFile {
  _Photo(String name) : super('assets/$name');
  int reads = 0;
  @override
  Future<int> length() async => 10;
  @override
  Future<Uint8List> readAsBytes() async {
    if (++reads > 1) throw StateError('임시 파일은 선택 후 사라졌습니다.');
    return Uint8List.fromList([137, 80, 78, 71]);
  }
}

class _BrokenPhoto extends _Photo {
  _BrokenPhoto(super.name);
  @override
  Future<Uint8List> readAsBytes() async => throw const FileSystemException(
    'Cannot open file',
    '/private/secret/photo.png',
  );
}

class _Picker extends ImagePicker {
  _Picker(this.images);
  final List<XFile> images;
  bool? fullMetadata;
  @override
  Future<List<XFile>> pickMultiImage({
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    int? limit,
    bool requestFullMetadata = true,
  }) async {
    fullMetadata = requestFullMetadata;
    return images;
  }
}

class _Api implements ApiClient {
  int uploads = 0;
  bool failSave = false;
  List<String> keys = [];
  List<String> urls = [];
  Map<String, dynamic>? lastSave;
  @override
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async => Response<T>(
    requestOptions: RequestOptions(path: path),
    statusCode: 200,
    data:
        {
              'success': true,
              'data': {
                'id': 'one',
                'title': '입주민을 위한 서비스 신청',
                'description': '기존 공고 화면과 같은 글꼴과 여백으로 안내합니다.',
                'applicationStartAt': '2026-10-23T00:00:00Z',
                'applicationEndAt': '2026-10-29T00:00:00Z',
                'serviceStartAt': '2026-10-30T00:00:00Z',
                'serviceEndAt': '2026-10-30T01:00:00Z',
                'status': 'RECRUITING',
                'imageKeys': keys,
                'imageUrls': urls,
                'canManage': true,
                'canClose': true,
                'capacity': 2,
                'applicantCount': 1,
              },
            }
            as T,
  );
  @override
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    if (path.endsWith('/images')) {
      uploads++;
      expect(data, isA<FormData>());
      expect((data as FormData).files.single.key, 'image');
      return Response<T>(
        requestOptions: RequestOptions(path: path),
        data:
            {
                  'success': true,
                  'data': {'key': 'uploaded-key'},
                }
                as T,
      );
    }
    lastSave = Map<String, dynamic>.from(data as Map);
    if (failSave) {
      throw const ApiException(message: '테스트 저장 실패', errorCode: 'TEST_ERROR');
    }
    return Response<T>(requestOptions: RequestOptions(path: path));
  }

  @override
  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) => post<T>(path, data: data);
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('Unexpected API operation');
}
