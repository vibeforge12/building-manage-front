import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:building_manage_front/modules/admin/data/datasources/resident_remote_datasource.dart';
import 'package:building_manage_front/core/network/exceptions/api_exception.dart';
import 'package:building_manage_front/shared/widgets/custom_confirmation_dialog.dart';

class ResidentManagementScreen extends ConsumerStatefulWidget {
  const ResidentManagementScreen({super.key});

  @override
  ConsumerState<ResidentManagementScreen> createState() => _ResidentManagementScreenState();
}

class _ResidentManagementScreenState extends ConsumerState<ResidentManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<Map<String, dynamic>> _verifiedResidents = [];
  List<Map<String, dynamic>> _pendingResidents = [];

  bool _isLoadingVerified = false;
  bool _isLoadingPending = false;

  String? _errorMessageVerified;
  String? _errorMessagePending;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadVerifiedResidents();
    _loadPendingResidents();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadVerifiedResidents() async {
    setState(() {
      _isLoadingVerified = true;
      _errorMessageVerified = null;
    });

    try {
      final residentDataSource = ref.read(residentRemoteDataSourceProvider);
      final response = await residentDataSource.getResidents(
        isVerified: true,
        status: 'ACTIVE', // ACTIVE 상태인 입주민만 조회
      );

      if (response['success'] == true) {
        final data = response['data'] as Map<String, dynamic>;
        setState(() {
          _verifiedResidents = List<Map<String, dynamic>>.from(data['items'] ?? []);
        });
      }
    } catch (e) {
      setState(() {
        if (e is ApiException) {
          _errorMessageVerified = e.userFriendlyMessage;
        } else {
          _errorMessageVerified = '입주민 목록을 불러오는 중 오류가 발생했습니다.';
        }
      });
    } finally {
      setState(() {
        _isLoadingVerified = false;
      });
    }
  }

  Future<void> _loadPendingResidents() async {
    setState(() {
      _isLoadingPending = true;
      _errorMessagePending = null;
    });

    try {
      final residentDataSource = ref.read(residentRemoteDataSourceProvider);
      final response = await residentDataSource.getResidents(isVerified: false);

      if (response['success'] == true) {
        final data = response['data'] as Map<String, dynamic>;
        setState(() {
          _pendingResidents = List<Map<String, dynamic>>.from(data['items'] ?? []);
        });
      }
    } catch (e) {
      setState(() {
        if (e is ApiException) {
          _errorMessagePending = e.userFriendlyMessage;
        } else {
          _errorMessagePending = '입주민 목록을 불러오는 중 오류가 발생했습니다.';
        }
      });
    } finally {
      setState(() {
        _isLoadingPending = false;
      });
    }
  }

  Future<void> _verifyResident(String residentId, String residentName) async {
    print('✅ _verifyResident 호출: residentId=$residentId, residentName=$residentName');

    final confirmed = await showCustomConfirmationDialog(
      context: context,
      content: const Text(
        '입주민 등록하시겠습니까?',
        style: TextStyle(
          fontFamily: 'Pretendard',
          fontWeight: FontWeight.w700,
          fontSize: 20,
          color: Color(0xFF464A4D),
        ),
      ),
      confirmText: '예',
      cancelText: '아니오',
      isDestructive: false,
    );

    print('✅ 다이얼로그 결과: confirmed=$confirmed');

    if (confirmed != true) {
      print('❌ 등록 취소됨');
      return;
    }

    print('🔄 승인 진행 시작...');

    try {
      final residentDataSource = ref.read(residentRemoteDataSourceProvider);
      print('📤 verifyResident API 호출 중...');
      await residentDataSource.verifyResident(residentId: residentId);

      print('✅ 승인 API 성공!');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$residentName 입주민이 승인되었습니다.'),
            backgroundColor: Colors.green,
          ),
        );

        print('🔄 목록 새로고침 시작...');
        await _loadPendingResidents();
        await _loadVerifiedResidents();
        print('✅ 목록 새로고침 완료!');
      }
    } catch (e) {
      print('❌ 승인 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is ApiException ? e.userFriendlyMessage : '입주민 승인 중 오류가 발생했습니다.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectResident(String residentId, String residentName) async {
    print('❌ _rejectResident 호출: residentId=$residentId, residentName=$residentName');

    final confirmed = await showCustomConfirmationDialog(
      context: context,
      content: const Text(
        '입주민 거절하시겠습니까?',
        style: TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 14,
          color: Color(0xFF464A4D),
        ),
      ),
      confirmText: '예',
      cancelText: '아니오',
      isDestructive: true,
    );

    print('✅ 다이얼로그 결과: confirmed=$confirmed');

    if (confirmed != true) {
      print('❌ 거절 취소됨');
      return;
    }

    print('🔄 거절 진행 시작...');

    try {
      final residentDataSource = ref.read(residentRemoteDataSourceProvider);
      print('📤 rejectResident API 호출 중...');
      await residentDataSource.rejectResident(residentId: residentId);

      print('✅ 거절 API 성공!');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$residentName 입주민이 거절되었습니다.'),
            backgroundColor: Colors.green,
          ),
        );

        print('🔄 목록 새로고침 시작...');
        await _loadPendingResidents();
        print('✅ 목록 새로고침 완료!');
      }
    } catch (e) {
      print('❌ 거절 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is ApiException ? e.userFriendlyMessage : '입주민 거절 중 오류가 발생했습니다.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteVerifiedResident(String residentId, String residentName) async {
    print('🗑️ _deleteVerifiedResident 호출: residentId=$residentId, residentName=$residentName');

    final confirmed = await showCustomConfirmationDialog(
      context: context,
      content: const Text(
        '입주민을 삭제하시겠습니까?',
        style: TextStyle(
          fontFamily: 'Pretendard',
          fontWeight: FontWeight.w700,
          fontSize: 20,
          color: Color(0xFF464A4D),
        ),
      ),
      confirmText: '예',
      cancelText: '아니오',
      isDestructive: true,
    );

    print('✅ 다이얼로그 결과: confirmed=$confirmed');

    if (confirmed != true) {
      print('❌ 삭제 취소됨');
      return;
    }

    print('🔄 삭제 진행 시작...');

    try {
      final residentDataSource = ref.read(residentRemoteDataSourceProvider);
      print('📤 deleteResident API 호출 중...');
      await residentDataSource.rejectResident(residentId: residentId);

      print('✅ 삭제 API 성공!');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$residentName 입주민이 삭제되었습니다.'),
            backgroundColor: Colors.green,
          ),
        );

        print('🔄 목록 새로고침 시작...');
        await _loadVerifiedResidents();
        print('✅ 목록 새로고침 완료!');
      }
    } catch (e) {
      print('❌ 삭제 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is ApiException ? e.userFriendlyMessage : '입주민 삭제 중 오류가 발생했습니다.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          '입주민 관리',
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: Color(0xFF464A4D),
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(89),
          child: Column(
            children: [
              const Divider(height: 1, thickness: 1, color: Color(0xFFE8EEF2)),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _buildSegmentedTabBar(),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildVerifiedResidentsTab(), // 건물
          _buildPendingResidentsTab(),  // 신규 입주민
        ],
      ),
    );
  }

  /// 세그먼티드 TabBar (건물 / 신규 입주민)
  Widget _buildSegmentedTabBar() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFFEFF3F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        labelPadding: EdgeInsets.zero,
        indicator: BoxDecoration(
          color: const Color(0xFF006FFF),
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: const Color(0xFF757B80),
        labelStyle: const TextStyle(
          fontFamily: 'Pretendard',
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'Pretendard',
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        tabs: const [
          Tab(text: '입주민'),
          Tab(text: '신규 입주민'),
        ],
      ),
    );
  }

  /// 탭1: 기존 입주민(건물) — 호수별 그룹화
  Widget _buildVerifiedResidentsTab() {
    if (_isLoadingVerified) return const Center(child: CircularProgressIndicator());
    if (_errorMessageVerified != null) {
      return _errorBox(_errorMessageVerified!, _loadVerifiedResidents);
    }
    if (_verifiedResidents.isEmpty) {
      return const Center(
        child: Text('등록된 입주민이 없습다.', style: TextStyle(color: Colors.grey)),
      );
    }

    // 호수별로 그룹화: "101동 1001호" 형태로
    final Map<String, List<Map<String, dynamic>>> groupedByHosu = {};
    for (final resident in _verifiedResidents) {
      final dong = resident['dong'] ?? '';
      final hosu = resident['hosu'] ?? '';
      final key = hosu;

      if (!groupedByHosu.containsKey(key)) {
        groupedByHosu[key] = [];
      }
      groupedByHosu[key]!.add(resident);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: groupedByHosu.length,
      itemBuilder: (context, index) {
        final hosuKey = groupedByHosu.keys.elementAt(index);
        final residents = groupedByHosu[hosuKey]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 호수 헤더 (Section header)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text(
                hosuKey,
                style: const TextStyle(
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  color: Color(0xFF17191A),
                ),
              ),
            ),
            // 해당 호수의 입주민 목록
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: residents.map((resident) {
                  final residentId = resident['id']?.toString() ?? '';
                  final name = resident['name'] ?? '이름 없음';

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(
                              fontFamily: 'Pretendard',
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: Color(0xFF17191A),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _deleteVerifiedResident(residentId, name),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF006FFF),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              '삭제',
                              style: TextStyle(
                                fontFamily: 'Pretendard',
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  /// 탭2: 신규 입주민(승인 대기) — 섹션 타이틀 + Pill 버튼
  Widget _buildPendingResidentsTab() {
    if (_isLoadingPending) return const Center(child: CircularProgressIndicator());
    if (_errorMessagePending != null) {
      return _errorBox(_errorMessagePending!, _loadPendingResidents);
    }
    if (_pendingResidents.isEmpty) {
      return const Center(
        child: Text('승인 대기 중인 입주민이 없습니다.', style: TextStyle(color: Colors.grey)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: Text(
            '신규 입주민 정보',
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: Color(0xFF17191A),
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            itemCount: _pendingResidents.length,
            separatorBuilder: (_, __) => const SizedBox(height: 20),
            itemBuilder: (context, index) {
              final r = _pendingResidents[index];
              final residentId = r['id']?.toString() ?? '';
              final name = r['name'] ?? '이름 없음';
              final dong = r['dong'] ?? '';
              final hosu = r['hosu'] ?? '';

              // 시안은 "105호"만 보이지만, 필요하면 '$dong동 $hosu호'로 바꿔도 됨
              final subText = (dong.isEmpty)
                  ? hosu
                  : '$dong동 $hosu호';

              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 좌측 텍스트
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: Color(0xFF17191A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subText,
                          style: const TextStyle(
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w400,
                            fontSize: 13,
                            color: Color(0xFF757B80),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _smallOutlinedButton(
                    label: '거절',
                    onPressed: () => _rejectResident(residentId, name),
                  ),
                  const SizedBox(width: 8),
                  _smallFilledButton(
                    label: '등록',
                    onPressed: () => _verifyResident(residentId, name),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  /// 작은 Outlined Pill 버튼
  Widget _smallOutlinedButton({required String label, required VoidCallback onPressed}) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 32),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        side: const BorderSide(color: Color(0xFFE8EEF2),),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(
          fontFamily: 'Pretendard',
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
        foregroundColor: const Color(0xFF464A4D),
      ),
      child: Text(label),
    );
  }

  /// 작은 Filled Pill 버튼
  Widget _smallFilledButton({required String label, required VoidCallback onPressed}) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 32),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        backgroundColor: const Color(0xFF006FFF),
        shape: RoundedRectangleBorder(      // ← 여기 변경
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(
          fontFamily: 'Pretendard',
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
      child: Text(label),
    );
  }

  /// 에러 공통 위젯
  Widget _errorBox(String msg, Future<void> Function() retry) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(msg, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: retry, child: const Text('다시 시도')),
        ],
      ),
    );
  }
}
