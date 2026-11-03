import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/error_message.dart';
import '../domain/entities/complaint_actions.dart';
import 'complaint_actions_providers.dart';

Future<void> openComplaintReplyForm(
  BuildContext context,
  WidgetRef ref, {
  required String complaintId,
  required String title,
  required bool isAdmin,
  required VoidCallback onChanged,
  ComplaintReply? reply,
}) async {
  await context.pushNamed<bool>(
    isAdmin ? 'adminComplaintResolve' : 'complaintResolve',
    pathParameters: {'complaintId': complaintId},
    extra: {'title': title, 'reply': reply},
  );
  if (!context.mounted) return;
  ref.invalidate(complaintActionsProvider(complaintId));
  onChanged();
}

class ComplaintResolveBar extends ConsumerWidget {
  final String complaintId;
  final String title;
  final bool isAdmin;
  final VoidCallback onChanged;
  const ComplaintResolveBar({
    super.key,
    required this.complaintId,
    required this.title,
    required this.isAdmin,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actions = ref.watch(complaintActionsProvider(complaintId));
    return actions.when(
      loading: () => const SizedBox.shrink(),
      error: (error, _) => SafeArea(
        child: TextButton(
          onPressed: () =>
              ref.invalidate(complaintActionsProvider(complaintId)),
          child: Text(
            '${userMessageOf(error, fallback: '처리 권한을 확인하지 못했습니다.')} 다시 시도',
          ),
        ),
      ),
      data: (data) => !data.canResolve
          ? const SizedBox.shrink()
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: SizedBox(
                  height: 48,
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => openComplaintReplyForm(
                      context,
                      ref,
                      complaintId: complaintId,
                      title: title,
                      isAdmin: isAdmin,
                      onChanged: onChanged,
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF006FFF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      isAdmin ? '직접 처리' : '처리 등록',
                      style: const TextStyle(
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

class ComplaintReplyMetadata extends ConsumerWidget {
  final String complaintId;
  final String title;
  final String? resultId;
  final bool isAdmin;
  final VoidCallback? onChanged;
  const ComplaintReplyMetadata({
    super.key,
    required this.complaintId,
    required this.title,
    this.resultId,
    this.isAdmin = false,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(complaintActionsProvider(complaintId)).valueOrNull;
    if (data == null || data.results.isEmpty) return const SizedBox.shrink();
    final matches = data.results.where((result) => result.id == resultId);
    final reply = resultId == null ? data.results.last : matches.firstOrNull;
    if (reply == null) return const SizedBox.shrink();
    final roleName = reply.authorRole == 'manager' ? '총관리자' : '담당자';
    final edited = reply.editedAt;
    final metadata = [
      if (reply.authorName.isNotEmpty) '$roleName ${reply.authorName}',
      if (edited != null)
        '${DateFormat('yyyy.MM.dd HH:mm').format(edited.toLocal())} 수정${reply.editorName == null ? '' : ' · ${reply.editorName}'}',
    ].join('\n');
    return Row(
      children: [
        Expanded(
          child: Text(
            metadata,
            style: const TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 12,
              color: Color(0xFF757B80),
              height: 1.6,
            ),
          ),
        ),
        if (reply.canEdit && onChanged != null)
          TextButton(
            onPressed: () => openComplaintReplyForm(
              context,
              ref,
              complaintId: complaintId,
              title: title,
              isAdmin: isAdmin,
              onChanged: onChanged!,
              reply: reply,
            ),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF006FFF),
            ),
            child: const Text(
              '답변 수정',
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}
