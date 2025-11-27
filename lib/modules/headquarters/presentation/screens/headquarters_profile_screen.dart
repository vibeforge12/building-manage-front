import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:building_manage_front/modules/auth/presentation/providers/auth_state_provider.dart';
import 'package:building_manage_front/modules/resident/presentation/widgets/consent_detail_sheet.dart';
import 'package:building_manage_front/shared/constants/legal_documents.dart';

class HeadquartersProfileScreen extends ConsumerWidget {
  const HeadquartersProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 상단 네비게이션 바
            _buildTopBar(context),

            // 내 정보 컨텐츠
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),

                      // 프로필 아이콘
                      Center(
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF2F8FC),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.business,
                            size: 60,
                            color: Color(0xFF006FFF),
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // 정보 항목들
                      _buildInfoItem('이름', currentUser?.name ?? '-'),
                      _buildDivider(),
                      _buildInfoItem('역할', '본사'),
                      _buildDivider(),
                      _buildActionItem(
                        context,
                        '비밀번호 수정',
                        () => context.push('/headquarters/change-password'),
                      ),

                      const SizedBox(height: 32),

                      // 약관 및 정책 섹션
                      const Text(
                        '약관 및 정책',
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildDivider(),
                      _buildActionItem(
                        context,
                        '서비스 이용약관',
                        () => ConsentDetailSheet.show(
                          context,
                          title: '서비스 이용약관',
                          content: LegalDocuments.termsOfService,
                        ),
                      ),
                      _buildDivider(),
                      _buildActionItem(
                        context,
                        '개인정보 처리방침',
                        () => ConsentDetailSheet.show(
                          context,
                          title: '개인정보 처리방침',
                          content: LegalDocuments.privacyPolicy,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      height: 48,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFE8EEF2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 20),
            onPressed: () => context.pop(),
            padding: const EdgeInsets.all(12),
          ),
          const Expanded(
            child: Center(
              child: Text(
                '내 정보',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: Color(0xFF17191A),
                ),
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w400,
              fontSize: 16,
              color: Color(0xFF757B80),
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: Color(0xFF17191A),
              ),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      color: const Color(0xFFE8EEF2),
    );
  }

  Widget _buildActionItem(BuildContext context, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w400,
                fontSize: 16,
                color: Color(0xFF757B80),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Color(0xFF757B80),
            ),
          ],
        ),
      ),
    );
  }
}
