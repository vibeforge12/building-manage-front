import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:building_manage_front/modules/admin/presentation/providers/admin_providers.dart';
import 'package:building_manage_front/shared/widgets/custom_confirmation_dialog.dart';

class ResidentDetailScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> resident;

  const ResidentDetailScreen({
    super.key,
    required this.resident,
  });

  @override
  ConsumerState<ResidentDetailScreen> createState() => _ResidentDetailScreenState();
}

class _ResidentDetailScreenState extends ConsumerState<ResidentDetailScreen> {
  bool _isDeleting = false;

  Future<void> _deleteResident() async {
    final residentId = widget.resident['id']?.toString() ?? '';
    if (residentId.isEmpty) return;

    final confirmed = await showCustomConfirmationDialog(
      context: context,
      title: '',
      content: const Text(
        '입주민을 삭제하시겠습니까?',
        style: TextStyle(
          fontFamily: 'Pretendard',
          fontWeight: FontWeight.w700,
          fontSize: 20,
          color: Colors.black,
        ),
        textAlign: TextAlign.center,
      ),
      confirmText: '예',
      cancelText: '아니오',
      isDestructive: true,
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isDeleting = true);

    try {
      final rejectResidentUseCase = ref.read(rejectResidentUseCaseProvider);
      await rejectResidentUseCase.execute(residentId: residentId);

      if (mounted) {
        context.pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isDeleting = false);
        await showCustomConfirmationDialog(
          context: context,
          title: '삭제 실패',
          content: Text(
            '입주민 삭제 중 오류가 발생했습니다.\n$e',
            style: const TextStyle(fontSize: 14),
          ),
          confirmText: '확인',
          cancelText: '',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.resident['name'] ?? '이름 없음';
    final dong = widget.resident['dong'] ?? '';
    final hosu = widget.resident['hosu'] ?? '';
    final phoneNumber = widget.resident['phoneNumber'] ?? '';
    final username = widget.resident['username'] ?? '';
    final unit = [dong, hosu].where((e) => e.toString().isNotEmpty).join(' ');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF17191A)),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          '입주민 상세',
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: Color(0xFF17191A),
          ),
        ),
        centerTitle: true,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(
            height: 1,
            thickness: 1,
            color: Color(0xFFE8EEF2),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('이름', name),
            _divider(),
            _buildInfoRow('동/호수', unit.isEmpty ? '-' : unit),
            _divider(),
            _buildInfoRow('아이디', username.isEmpty ? '-' : username),
            _divider(),
            _buildInfoRow('전화번호', phoneNumber.isEmpty ? '-' : phoneNumber),
            const SizedBox(height: 40),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: _isDeleting ? null : _deleteResident,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                disabledBackgroundColor: const Color(0xFFCCCCCC),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isDeleting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text(
                      '입주민 삭제',
                      style: TextStyle(
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: Color(0xFF17191A),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w400,
                fontSize: 14,
                color: Color(0xFF17191A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(height: 1, color: const Color(0xFFE8EEF2));
  }
}
