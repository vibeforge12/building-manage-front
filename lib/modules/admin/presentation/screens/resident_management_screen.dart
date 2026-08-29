import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:building_manage_front/modules/admin/presentation/providers/admin_providers.dart';
import 'package:building_manage_front/shared/widgets/custom_confirmation_dialog.dart';
import 'package:building_manage_front/shared/widgets/error_alert.dart';
import 'package:building_manage_front/core/utils/error_message.dart';

class ResidentManagementScreen extends ConsumerStatefulWidget {
  const ResidentManagementScreen({super.key});

  @override
  ConsumerState<ResidentManagementScreen> createState() => _ResidentManagementScreenState();
}

class _ResidentManagementScreenState extends ConsumerState<ResidentManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const int _pageSize = 20;

  final TextEditingController _searchController = TextEditingController();
  String _keyword = '';

  final ScrollController _verifiedScroll = ScrollController();
  final ScrollController _pendingScroll = ScrollController();

  List<Map<String, dynamic>> _verifiedResidents = [];
  List<Map<String, dynamic>> _pendingResidents = [];

  int _verifiedPage = 1;
  int _pendingPage = 1;
  bool _verifiedHasMore = true;
  bool _pendingHasMore = true;

  bool _isLoadingVerified = false;
  bool _isLoadingPending = false;
  bool _isLoadingMoreVerified = false;
  bool _isLoadingMorePending = false;

  String? _errorMessageVerified;
  String? _errorMessagePending;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _verifiedScroll.addListener(() => _onScroll(isVerified: true));
    _pendingScroll.addListener(() => _onScroll(isVerified: false));
    _loadVerifiedResidents(reset: true);
    _loadPendingResidents(reset: true);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _verifiedScroll.dispose();
    _pendingScroll.dispose();
    super.dispose();
  }

  /// 입주민 한 페이지 조회 (20개 단위, 검색어 적용)
  Future<List<Map<String, dynamic>>> _fetchResidentPage({
    required bool isVerified,
    required int page,
  }) async {
    final getResidentsUseCase = ref.read(getResidentsUseCaseProvider);
    final batch = await getResidentsUseCase.execute(
      isVerified: isVerified,
      status: 'ACTIVE',
      page: page,
      limit: _pageSize,
      keyword: _keyword.isEmpty ? null : _keyword,
    );
    return batch.map((resident) => resident.toJson()).toList();
  }

  /// 스크롤 하단 근접 시 다음 페이지 로드
  void _onScroll({required bool isVerified}) {
    final sc = isVerified ? _verifiedScroll : _pendingScroll;
    if (!sc.hasClients) return;
    if (sc.position.pixels >= sc.position.maxScrollExtent - 300) {
      if (isVerified) {
        _loadMoreVerified();
      } else {
        _loadMorePending();
      }
    }
  }

  /// 검색 실행 (두 탭 모두 첫 페이지부터 다시 조회)
  void _applySearch(String value) {
    final next = value.trim();
    if (next == _keyword) return;
    setState(() => _keyword = next);
    _loadVerifiedResidents(reset: true);
    _loadPendingResidents(reset: true);
  }

  Future<void> _loadVerifiedResidents({bool reset = false}) async {
    setState(() {
      _isLoadingVerified = true;
      _errorMessageVerified = null;
      if (reset) _verifiedResidents = [];
    });

    try {
      final items = await _fetchResidentPage(isVerified: true, page: 1);
      setState(() {
        _verifiedResidents = items;
        _verifiedPage = 1;
        _verifiedHasMore = items.length == _pageSize;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessageVerified = userMessageOf(e, fallback: '입주민 목록을 불러오지 못했습니다.');
      });
    } finally {
      if (mounted) {
        setState(() => _isLoadingVerified = false);
      }
    }
  }

  Future<void> _loadMoreVerified() async {
    if (_isLoadingMoreVerified || _isLoadingVerified || !_verifiedHasMore) return;
    setState(() => _isLoadingMoreVerified = true);
    try {
      final next = _verifiedPage + 1;
      final items = await _fetchResidentPage(isVerified: true, page: next);
      setState(() {
        _verifiedResidents = [..._verifiedResidents, ...items];
        _verifiedPage = next;
        _verifiedHasMore = items.length == _pageSize;
      });
    } catch (_) {
      // 추가 로드 실패는 조용히 무시 (다음 스크롤에서 재시도)
    } finally {
      if (mounted) setState(() => _isLoadingMoreVerified = false);
    }
  }

  Future<void> _loadPendingResidents({bool reset = false}) async {
    setState(() {
      _isLoadingPending = true;
      _errorMessagePending = null;
      if (reset) _pendingResidents = [];
    });

    try {
      // status: 'ACTIVE'로 DELETED 상태 입주민 제외
      final items = await _fetchResidentPage(isVerified: false, page: 1);
      setState(() {
        _pendingResidents = items;
        _pendingPage = 1;
        _pendingHasMore = items.length == _pageSize;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessagePending = userMessageOf(e, fallback: '입주민 목록을 불러오지 못했습니다.');
      });
    } finally {
      if (mounted) {
        setState(() => _isLoadingPending = false);
      }
    }
  }

  Future<void> _loadMorePending() async {
    if (_isLoadingMorePending || _isLoadingPending || !_pendingHasMore) return;
    setState(() => _isLoadingMorePending = true);
    try {
      final next = _pendingPage + 1;
      final items = await _fetchResidentPage(isVerified: false, page: next);
      setState(() {
        _pendingResidents = [..._pendingResidents, ...items];
        _pendingPage = next;
        _pendingHasMore = items.length == _pageSize;
      });
    } catch (_) {
      // 추가 로드 실패는 조용히 무시
    } finally {
      if (mounted) setState(() => _isLoadingMorePending = false);
    }
  }

  Future<void> _verifyResident(String residentId, String residentName) async {

    final confirmed = await showCustomConfirmationDialog(
      context: context,
      title: '',
      content: const Text(
        '입주민을 등록하시겠습니까?',
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
      isDestructive: false,
    );

    if (confirmed != true) {
      return;
    }

    try {
      // UseCase를 통한 입주민 승인 (비즈니스 로직 포함)
      final verifyResidentUseCase = ref.read(verifyResidentUseCaseProvider);
      await verifyResidentUseCase.execute(residentId: residentId);

      if (mounted) {
        await _loadPendingResidents();
        await _loadVerifiedResidents();
      }
    } catch (e) {
      if (!mounted) return;
      await showErrorAlert(
        context,
        title: '승인 실패',
        error: e,
        fallback: '입주민을 승인하지 못했습니다. 잠시 후 다시 시도해 주세요.',
      );
    }
  }

  Future<void> _rejectResident(String residentId, String residentName) async {
    final confirmed = await showCustomConfirmationDialog(
      context: context,
      title: '',
      content: const Text(
        '입주민을 거절하시겠습니까?',
        style: TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Colors.black,
        ),
        textAlign: TextAlign.center,
      ),
      confirmText: '예',
      cancelText: '아니오',
      isDestructive: true,
    );

    if (confirmed != true) {
      return;
    }

    try {
      // UseCase를 통한 입주민 거절 (비즈니스 로직 포함)
      final rejectResidentUseCase = ref.read(rejectResidentUseCaseProvider);
      await rejectResidentUseCase.execute(residentId: residentId);

      if (mounted) {
        await _loadPendingResidents();
      }
    } catch (e) {
      // 에러 모달 표시
      if (mounted) {
        final errorMessage = userMessageOf(
          e,
          fallback: '입주민을 거절하지 못했습니다. 잠시 후 다시 시도해 주세요.',
        );
        await showCustomConfirmationDialog(
          context: context,
          title: '',
          content: Text(
            errorMessage,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          confirmText: '확인',
          cancelText: '',
          barrierDismissible: true,
          confirmOnLeft: true,
        );
      }
    }
  }

  Future<void> _deleteVerifiedResident(String residentId, String residentName) async {

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

    if (confirmed != true) {
      return;
    }

    try {
      // UseCase를 통한 입주민 삭제 (비즈니스 로직 포함)
      final rejectResidentUseCase = ref.read(rejectResidentUseCaseProvider);
      await rejectResidentUseCase.execute(residentId: residentId);

      if (mounted) {
        await _loadVerifiedResidents();
      }
    } catch (e) {
      if (!mounted) return;
      await showErrorAlert(
        context,
        title: '삭제 실패',
        error: e,
        fallback: '입주민을 삭제하지 못했습니다. 잠시 후 다시 시도해 주세요.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
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
          preferredSize: const Size.fromHeight(54),
          child: Column(
            children: [
              Container(
                height: 1,
                color: const Color(0xFFE8EEF2),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                height: 53,
                child: Row(
                  children: [
                    Expanded(
                      child: _buildSegmentedTabBar(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      // 하단 고정 버튼·마지막 목록 항목이 시스템 내비게이션 바에 가리지 않도록 감싼다.
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchField(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildVerifiedResidentsTab(), // 건물
                  _buildPendingResidentsTab(), // 신규 입주민
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 검색창 — 입력 후 엔터 시 두 탭 모두 재조회.
  /// 서버가 이름·아이디·동·호수·전화번호를 부분 일치로 찾는다.
  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: TextField(
        controller: _searchController,
        textInputAction: TextInputAction.search,
        onSubmitted: _applySearch,
        decoration: InputDecoration(
          hintText: '이름 · 아이디 · 호실 · 전화번호 검색',
          hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: Color(0xFF757B80)),
          suffixIcon: _keyword.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFF757B80)),
                  onPressed: () {
                    _searchController.clear();
                    _applySearch('');
                  },
                )
              : null,
          filled: true,
          fillColor: const Color(0xFFF2F4F6),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        ),
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
      return Center(
        child: Text(
          _keyword.isNotEmpty ? '검색 결과가 없습니다.' : '등록된 입주민이 없습니다.',
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }

    // 동/호수별로 그룹화: "101동 1001호" 형태로
    final Map<String, List<Map<String, dynamic>>> groupedByHosu = {};
    for (final resident in _verifiedResidents) {
      final dong = resident['dong'] ?? '';
      final hosu = resident['hosu'] ?? '';
      final key = [dong, hosu].where((e) => e.toString().isNotEmpty).join(' ');

      if (!groupedByHosu.containsKey(key)) {
        groupedByHosu[key] = [];
      }
      groupedByHosu[key]!.add(resident);
    }

    final hosuKeys = groupedByHosu.keys.toList();

    return ListView.builder(
      controller: _verifiedScroll,
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: hosuKeys.length + (_isLoadingMoreVerified ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= hosuKeys.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        final hosuKey = hosuKeys[index];
        final residents = groupedByHosu[hosuKey]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 호수 헤더 (Section header)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text(
                _formatHosuDisplay(hosuKey),
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
                  final name = resident['name'] ?? '이름 없음';

                  return InkWell(
                    onTap: () async {
                      final result = await context.pushNamed(
                        'residentDetail',
                        extra: resident,
                      );
                      if (result == true && mounted) {
                        await _loadVerifiedResidents();
                      }
                    },
                    child: Padding(
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
                          const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Color(0xFF757B80),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            // 호수마다 구분줄 추가 (마지막 호수 제외)
            if (index < groupedByHosu.length - 1)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  height: 8,
                  color: const Color(0xFFF2F8FC),
                ),
              ),
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
      return Center(
        child: Text(
          _keyword.isNotEmpty ? '검색 결과가 없습니다.' : '승인 대기 중인 입주민이 없습니다.',
          style: const TextStyle(color: Colors.grey),
        ),
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
            controller: _pendingScroll,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            itemCount: _pendingResidents.length + (_isLoadingMorePending ? 1 : 0),
            separatorBuilder: (_, __) => const SizedBox(height: 20),
            itemBuilder: (context, index) {
              if (index >= _pendingResidents.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                );
              }
              final r = _pendingResidents[index];
              final residentId = r['id']?.toString() ?? '';
              final name = r['name'] ?? '이름 없음';
              final dong = r['dong'] ?? '';
              final hosu = r['hosu'] ?? '';

              // 시안은 "105호"만 보이지만, 필요하면 '$dong동 $hosu호'로 바꿔도 됨
              final subText = (dong.isEmpty)
                  ? hosu
                  : '$dong $hosu';

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

  /// 호수 표시 포맷팅 (일관성 있게 "호" 붙이기)
  String _formatHosuDisplay(String hosu) {
    if (hosu.isEmpty) return '미지정';
    // 이미 "호"로 끝나면 그대로, 아니면 "호" 추가
    if (hosu.endsWith('호')) {
      return hosu;
    }
    return hosu;
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
