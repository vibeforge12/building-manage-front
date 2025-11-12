import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:building_manage_front/modules/auth/presentation/providers/auth_state_provider.dart';

class NoticeManagementScreen extends ConsumerStatefulWidget {
  const NoticeManagementScreen({super.key});

  @override
  ConsumerState<NoticeManagementScreen> createState() => _NoticeManagementScreenState();
}

class _NoticeManagementScreenState extends ConsumerState<NoticeManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedFilter = '전체';
  String _selectedChip = '전체';

  // 임시 데이터
  final List<Map<String, dynamic>> _notices = [
    {'id': '1', 'title': '[미화] 건물 누수공사 공지드립니다'},
    {'id': '2', 'title': '[관리] 건물 소방점검 공지드립니다'},
    {'id': '3', 'title': '[방제] 공지드립니다'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 현재 로그인한 관리자의 정보
    final currentUser = ref.watch(currentUserProvider);
    // TODO: API 응답에서 건물명을 받아오도록 수정 필요
    final buildingName = currentUser?.name ?? '건물명';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        title: Text(
          buildingName,
          style: const TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: Color(0xFF464A4D),
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(55),
          child: Column(
            children: [
              Container(
                height: 1,
                color: const Color(0xFFE8EEF2),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                height: 54,
                child: Row(
                  children: [
                    // 탭 (좌측 정렬)
                    Expanded(
                      child: Row(
                        children: [
                          TabBar(
                            controller: _tabController,
                            isScrollable: true,
                            tabAlignment: TabAlignment.start,
                            indicatorColor: const Color(0xFF17191A),
                            indicatorWeight: 2,
                            indicatorSize: TabBarIndicatorSize.label,
                            labelColor: const Color(0xFF17191A),
                            unselectedLabelColor: const Color(0xFF17191A).withOpacity(0.5),
                            labelStyle: const TextStyle(
                              fontFamily: 'Pretendard',
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                            unselectedLabelStyle: const TextStyle(
                              fontFamily: 'Pretendard',
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                            labelPadding: const EdgeInsets.only(right: 32, top: 16, bottom: 16),
                            padding: EdgeInsets.zero,
                            dividerColor: Colors.transparent,
                            onTap: (index) {
                              setState(() {
                                // 탭이 변경되면 버튼 텍스트도 변경
                              });
                            },
                            tabs: const [
                              Tab(text: '공지사항'),
                              Tab(text: '이벤트'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // 등록 버튼 (우측)
                    TextButton.icon(
                      onPressed: () {
                        final isEvent = _tabController.index == 1;
                        context.push('/admin/notice-create?isEvent=$isEvent');
                      },
                      icon: const Icon(
                        Icons.add,
                        size: 20,
                        color: Colors.white,
                      ),
                      label: Text(
                        _tabController.index == 0 ? '공지 등록' : '이벤트 등록',
                        style: const TextStyle(
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFF006FFF),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          // 정렬 필터
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Color(0xFFE8EEF2),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      _showSortDialog(context);
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _selectedFilter,
                          style: const TextStyle(
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: Color(0xFF757B80),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.keyboard_arrow_down,
                          size: 16,
                          color: Color(0xFF757B80),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 칩스 필터
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Color(0xFFE8EEF2),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                _buildChip('전체', isActive: _selectedChip == '전체'),
                const SizedBox(width: 8),
                _buildChip('유저', isActive: _selectedChip == '유저'),
                const SizedBox(width: 8),
                _buildChip('담당자', isActive: _selectedChip == '담당자'),
              ],
            ),
          ),

          // 공지사항/이벤트 리스트
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildNoticeList(),
                _buildEventList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, {required bool isActive}) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedChip = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF006FFF) : Colors.white,
          border: Border.all(
            color: isActive ? const Color(0xFF006FFF) : const Color(0xFFE8EEF2),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: isActive ? Colors.white : const Color(0xFF464A4D),
          ),
        ),
      ),
    );
  }

  Widget _buildNoticeList() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _notices.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final notice = _notices[index];
        return _buildNoticeItem(notice);
      },
    );
  }

  Widget _buildEventList() {
    // 이벤트 리스트 (임시로 공지사항과 동일하게 표시)
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _notices.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final notice = _notices[index];
        return _buildNoticeItem(notice);
      },
    );
  }

  Widget _buildNoticeItem(Map<String, dynamic> notice) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: const Color(0xFFE8EEF2),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              notice['title'],
              style: const TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: Color(0xFF17191A),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 삭제 버튼
              GestureDetector(
                onTap: () {
                  // TODO: 삭제 기능
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                      color: const Color(0xFFE8EEF2),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '삭제',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: Color(0xFF464A4D),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // 수정 버튼
              GestureDetector(
                onTap: () {
                  // TODO: 수정 기능
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDF9FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '수정',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: Color(0xFF0683FF),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showSortDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('정렬'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSortOption('전체'),
              _buildSortOption('최신순'),
              _buildSortOption('오래된순'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortOption(String option) {
    return ListTile(
      title: Text(option),
      onTap: () {
        setState(() {
          _selectedFilter = option;
        });
        Navigator.pop(context);
      },
    );
  }
}
