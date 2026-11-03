import 'package:building_manage_front/core/network/exceptions/api_exception.dart';
import 'package:building_manage_front/modules/admin/domain/entities/complaint.dart';
import 'package:building_manage_front/modules/complaint_actions/domain/entities/complaint_actions.dart';
import 'package:building_manage_front/modules/complaint_actions/domain/repositories/complaint_actions_repository.dart';
import 'package:building_manage_front/modules/complaint_actions/domain/usecases/complaint_actions_use_case.dart';
import 'package:building_manage_front/modules/complaint_actions/presentation/complaint_action_widgets.dart';
import 'package:building_manage_front/modules/complaint_actions/presentation/complaint_actions_providers.dart';
import 'package:building_manage_front/modules/manager/presentation/screens/complaint_resolve_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

const _reply = ComplaintReply(
  id: 'r1',
  content: '기존 처리 내용',
  revision: 3,
  canEdit: true,
  authorName: '총관리자',
  authorRole: 'manager',
  imageKey: 'complaint-results/old.jpg',
);

class _Repository implements ComplaintActionsRepository {
  ComplaintActions state = const ComplaintActions(
    complaintId: 'c1',
    canResolve: true,
    results: [],
  );
  int resolveCalls = 0;
  int editCalls = 0;
  int? expectedRevision;
  bool? replacedImage;
  String? savedImage;
  String? savedContent;
  bool conflict = false;

  @override
  Future<ComplaintActions> getActions(String complaintId) async => state;

  @override
  Future<ComplaintActions> resolve(
    String complaintId,
    String content,
    String? imageKey,
  ) async {
    resolveCalls++;
    savedContent = content;
    state = const ComplaintActions(
      complaintId: 'c1',
      canResolve: false,
      results: [_reply],
    );
    return state;
  }

  @override
  Future<ComplaintActions> edit(
    String complaintId,
    String resultId,
    String content,
    int expectedRevision, {
    String? imageKey,
    bool replaceImage = false,
  }) async {
    editCalls++;
    this.expectedRevision = expectedRevision;
    replacedImage = replaceImage;
    savedImage = imageKey;
    savedContent = content;
    if (conflict) {
      throw const ApiException(
        message: '다른 사람이 답변을 수정했습니다.',
        statusCode: 409,
        errorCode: 'CONFLICT',
      );
    }
    return state;
  }
}

class _Detail extends ConsumerWidget {
  const _Detail();
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    body: Column(
      children: [
        ComplaintResolveBar(
          complaintId: 'c1',
          title: '테스트 민원',
          isAdmin: true,
          onChanged: () {},
        ),
        ComplaintReplyMetadata(
          complaintId: 'c1',
          title: '테스트 민원',
          isAdmin: true,
          onChanged: () {},
        ),
      ],
    ),
  );
}

void main() {
  testWidgets(
    'conflict keeps the draft and requires an explicit choice before leaving',
    (tester) async {
      final repo = _Repository()..conflict = true;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            complaintActionsUseCaseProvider.overrideWithValue(
              ComplaintActionsUseCase(repo),
            ),
          ],
          child: const MaterialApp(
            home: ComplaintResolveScreen(
              complaintId: 'c1',
              complaintTitle: '테스트 민원',
              complaintData: {},
              reply: _reply,
            ),
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), '보존해야 하는 수정 내용');
      await tester.pump();
      final submit = tester
          .widget<TextButton>(
            find.ancestor(
              of: find.text('저장'),
              matching: find.byType(TextButton),
            ),
          )
          .onPressed!;
      submit();
      submit();
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.tap(find.text('확인'));
      await tester.pumpAndSettle();
      expect(repo.editCalls, 1);
      expect(find.text('다른 사람이 답변을 수정했습니다.'), findsOneWidget);
      await tester.tap(find.text('확인'));
      await tester.pumpAndSettle();
      expect(find.text('보존해야 하는 수정 내용'), findsOneWidget);
      expect(find.text('최신 답변 확인'), findsOneWidget);
      final saveButton = tester.widget<TextButton>(
        find.ancestor(of: find.text('저장'), matching: find.byType(TextButton)),
      );
      expect(saveButton.onPressed, isNull);
      await tester.tap(find.text('최신 답변 확인'));
      await tester.pumpAndSettle();
      expect(
        find.text('현재 입력한 내용은 저장되지 않습니다. 필요한 내용은 복사한 후 이동해 주세요.'),
        findsOneWidget,
      );
      await tester.tap(find.text('계속 작성'));
      await tester.pumpAndSettle();
      expect(find.text('보존해야 하는 수정 내용'), findsOneWidget);
    },
  );

  test('completion date remains the result creation time after edits', () {
    final complaint = AdminComplaint.fromJson({
      'id': 'c1',
      'isResolved': true,
      'createdAt': '2026-10-28T00:00:00Z',
      'updatedAt': '2026-10-30T01:00:00Z',
      'results': [
        {'content': '수정된 답변', 'createdAt': '2026-10-29T00:00:00Z'},
      ],
    });
    expect(complaint.completedAt?.toUtc(), DateTime.utc(2026, 10, 29));
  });

  test(
    'legacy multiple replies use earliest completion and prefer server completion',
    () {
      final json = <String, dynamic>{
        'id': 'c1',
        'isResolved': true,
        'createdAt': '2026-10-28T00:00:00Z',
        'results': [
          {'content': '나중 답변', 'createdAt': '2026-10-30T00:00:00Z'},
          {'content': '첫 답변', 'createdAt': '2026-10-29T00:00:00Z'},
          {'content': '그 다음 답변', 'createdAt': '2026-10-29T06:00:00Z'},
        ],
      };
      expect(
        AdminComplaint.fromJson(json).completedAt?.toUtc(),
        DateTime.utc(2026, 10, 29),
      );
      json['completedAt'] = '2026-10-28T12:00:00Z';
      expect(
        AdminComplaint.fromJson(json).completedAt?.toUtc(),
        DateTime.utc(2026, 10, 28, 12),
      );
    },
  );

  test(
    'editing carries original revision and distinguishes keeping/removing image',
    () async {
      final repo = _Repository();
      final useCase = ComplaintActionsUseCase(repo);
      await useCase.save(complaintId: 'c1', content: '  새 답변  ', reply: _reply);
      expect(repo.expectedRevision, 3);
      expect(repo.savedContent, '새 답변');
      expect(repo.replacedImage, isFalse);
      await useCase.save(
        complaintId: 'c1',
        content: '사진 삭제',
        reply: _reply,
        replaceImage: true,
      );
      expect(repo.replacedImage, isTrue);
      expect(repo.savedImage, isNull);
      await useCase.save(
        complaintId: 'c1',
        content: '사진 교체',
        reply: _reply,
        replaceImage: true,
        imageKey: 'complaint-results/new.jpg',
      );
      expect(repo.savedImage, 'complaint-results/new.jpg');
    },
  );

  test('blank and oversized content never reaches the server', () {
    final repo = _Repository();
    final useCase = ComplaintActionsUseCase(repo);
    expect(
      () => useCase.save(complaintId: 'c1', content: '  '),
      throwsA(isA<ApiException>()),
    );
    expect(
      () => useCase.save(complaintId: 'c1', content: 'a' * 10001),
      throwsA(isA<ApiException>()),
    );
    expect(repo.resolveCalls, 0);
  });

  test(
    'server conflict is preserved rather than silently overwriting',
    () async {
      final repo = _Repository()..conflict = true;
      await expectLater(
        ComplaintActionsUseCase(
          repo,
        ).save(complaintId: 'c1', content: '새 답변', reply: _reply),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 409),
        ),
      );
      expect(repo.editCalls, 1);
    },
  );

  testWidgets('read-only permissions hide resolving and editing', (
    tester,
  ) async {
    final repo = _Repository()
      ..state = const ComplaintActions(
        complaintId: 'c1',
        canResolve: false,
        results: [
          ComplaintReply(
            id: 'r1',
            content: '답변',
            revision: 1,
            canEdit: false,
            authorName: '담당자',
            authorRole: 'staff',
          ),
        ],
      );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          complaintActionsUseCaseProvider.overrideWithValue(
            ComplaintActionsUseCase(repo),
          ),
        ],
        child: const MaterialApp(home: _Detail()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('직접 처리'), findsNothing);
    expect(find.text('답변 수정'), findsNothing);
    expect(find.text('담당자 담당자'), findsOneWidget);
  });

  testWidgets(
    'HEAD resolves then edits from the same detail and confirmation cancel is safe',
    (tester) async {
      final repo = _Repository();
      final router = GoRouter(
        initialLocation: '/detail',
        routes: [
          GoRoute(path: '/detail', builder: (_, _) => const _Detail()),
          GoRoute(
            path: '/admin/complaint-resolve/:complaintId',
            name: 'adminComplaintResolve',
            builder: (_, state) {
              final extra = state.extra as Map;
              return ComplaintResolveScreen(
                complaintId: 'c1',
                complaintTitle: extra['title'] as String,
                complaintData: const {},
                reply: extra['reply'] as ComplaintReply?,
              );
            },
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            complaintActionsUseCaseProvider.overrideWithValue(
              ComplaintActionsUseCase(repo),
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('직접 처리'));
      await tester.pumpAndSettle();
      expect(find.text('민원 처리 등록'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '총관리자 처리 내용');
      await tester.pump();
      await tester.tap(find.text('등록'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('아니요'));
      await tester.pumpAndSettle();
      expect(repo.resolveCalls, 0);
      await tester.tap(find.text('등록'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('확인'));
      await tester.pumpAndSettle();
      expect(repo.resolveCalls, 1);
      expect(router.routeInformationProvider.value.uri.path, '/detail');
      expect(find.text('직접 처리'), findsNothing);
      await tester.tap(find.text('답변 수정'));
      await tester.pumpAndSettle();
      expect(find.text('기존 처리 내용'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '수정한 처리 내용');
      await tester.pump();
      await tester.tap(find.text('저장'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('확인'));
      await tester.pumpAndSettle();
      expect(repo.editCalls, 1);
      expect(repo.expectedRevision, 3);
      expect(repo.replacedImage, isFalse);
      expect(repo.savedContent, '수정한 처리 내용');
      expect(router.routeInformationProvider.value.uri.path, '/detail');
    },
  );
}
