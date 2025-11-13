import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:building_manage_front/modules/auth/presentation/providers/auth_state_provider.dart';
import 'package:building_manage_front/modules/admin/data/datasources/notice_remote_datasource.dart';
import 'package:building_manage_front/shared/widgets/custom_confirmation_dialog.dart';

class NoticeManagementScreen extends ConsumerStatefulWidget {
  const NoticeManagementScreen({super.key});

  @override
  ConsumerState<NoticeManagementScreen> createState() => _NoticeManagementScreenState();
}

class _NoticeManagementScreenState extends ConsumerState<NoticeManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedFilter = '최신순';
  String _selectedChip = '전체';
  bool _isLoading = false;

  // API에서 받은 데이터
  List<Map<String, dynamic>> _notices = [];
  List<Map<String, dynamic>> _events = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    // 초기 데이터 초기화
    _notices = [];
    _events = [];
    _loadNotices();
  }

  void _onTabChanged() {
    if (_tabController.index == 0) {
      _loadNotices();
    } else {
      _loadEvents();
    }
  }

  Future<void> _loadNotices() async {
    setState(() => _isLoading = true);
    try {
      final noticeDataSource = ref.read(noticeRemoteDataSourceProvider);
      final response = await noticeDataSource.getNotices(
        sortOrder: _selectedFilter == '오래된순' ? 'ASC' : 'DESC',
      );

      print('📌 API 응답: $response');
      print('📌 response["data"]: ${response["data"]}');
      print('📌 response["data"]["data"]: ${response["data"]["data"]}');

      if (mounted) {
        final noticeList = List<Map<String, dynamic>>.from(response['data']['data'] ?? []);
        print('📌 파싱된 공지사항 개수: ${noticeList.length}');
        setState(() {
          _notices = noticeList;
        });
      }
    } catch (e) {
      print('공지사항 목록 로드 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('공지사항 로드 실패: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    try {
      // TODO: 서버에서 이벤트 조회 API 완성되면 아래 주석 해제 후 더미 데이터 제거
      // final noticeDataSource = ref.read(noticeRemoteDataSourceProvider);
      // final response = await noticeDataSource.getEvents(
      //   sortOrder: _selectedFilter == '오래된순' ? 'ASC' : 'DESC',
      // );
      // final eventList = List<Map<String, dynamic>>.from(response['data']['data'] ?? []);

      // 임시 더미 데이터 (서버 API 준비 중)
      final eventList = <Map<String, dynamic>>[];

      if (mounted) {
        print('📌 파싱된 이벤트 개수: ${eventList.length}');
        setState(() {
          _events = eventList;
        });
      }
    } catch (e) {
      print('이벤트 목록 로드 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('이벤트 로드 실패: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_notices.isEmpty) {
      return Center(
        child: Text(
          '공지사항이 없습니다',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }

    // 칩 필터 적용
    final filteredNotices = _notices.where((notice) {
      if (_selectedChip == '전체') return true;
      final target = notice['target'] as String?;
      if (_selectedChip == '유저') return target == 'RESIDENT';
      if (_selectedChip == '담당자') return target == 'STAFF';
      return true;
    }).toList();

    if (filteredNotices.isEmpty) {
      return Center(
        child: Text(
          '해당하는 공지사항이 없습니다',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: filteredNotices.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final notice = filteredNotices[index];
        return _buildNoticeItem(notice, isEvent: false);
      },
    );
  }

  Widget _buildEventList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_events.isEmpty) {
      return Center(
        child: Text(
          '이벤트가 없습니다',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }

    // 칩 필터 적용
    final filteredEvents = _events.where((event) {
      if (_selectedChip == '전체') return true;
      final target = event['target'] as String?;
      if (_selectedChip == '유저') return target == 'RESIDENT';
      if (_selectedChip == '담당자') return target == 'STAFF';
      return true;
    }).toList();

    if (filteredEvents.isEmpty) {
      return Center(
        child: Text(
          '해당하는 이벤트가 없습니다',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: filteredEvents.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final event = filteredEvents[index];
        return _buildNoticeItem(event, isEvent: true);
      },
    );
  }

  void _showDeleteConfirmation(String noticeId, String noticeTitle, bool isEvent) async {
    final result = await showCustomConfirmationDialog(
      context: context,
      title: '${isEvent ? '이벤트' : '공지사항'}을 삭제하시겠습니까?',
      content: const SizedBox.shrink(),
      confirmText: '예',
      cancelText: '아니요',
      isDestructive: true,
      confirmOnLeft: true,
    );

    if (result == true) {
      _deleteNotice(noticeId, isEvent);
    }
  }

  Future<void> _deleteNotice(String noticeId, bool isEvent) async {
    try {
      final noticeDataSource = ref.read(noticeRemoteDataSourceProvider);

      if (isEvent) {
        await noticeDataSource.deleteEvent(noticeId);
      } else {
        await noticeDataSource.deleteNotice(noticeId);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${isEvent ? '이벤트' : '공지사항'}이 삭제되었습니다.'),
            backgroundColor: Colors.green,
          ),
        );
        // 목록 새로고침
        if (isEvent) {
          _loadEvents();
        } else {
          _loadNotices();
        }
      }
    } catch (e) {
      print('${isEvent ? '이벤트' : '공지사항'} 삭제 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('삭제 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildNoticeItem(Map<String, dynamic> notice, {bool isEvent = false}) {
    final id = notice['id'] as String? ?? '';
    final title = notice['title'] as String? ?? '제목 없음';
    final content = notice['content'] as String? ?? '';
    final createdAt = notice['createdAt'] as String? ?? '';

    // 날짜 포맷팅 (ISO 8601 → 간단한 형식)
    String formatDate(String dateStr) {
      try {
        final date = DateTime.parse(dateStr);
        return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      } catch (e) {
        return dateStr;
      }
    }

    return GestureDetector(
      onTap: () async {
        // 공지사항/이벤트 클릭 시 상세 조회 화면으로 이동
        final result = await context.push<bool>(
          '/admin/notice-detail/$id?isEvent=${isEvent.toString()}',
        );
        // 수정 후 돌아올 때 true가 반환되면 목록 새로고침
        if (result == true) {
          if (isEvent) {
            _loadEvents();
          } else {
            _loadNotices();
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: const Color(0xFFE8EEF2),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: Color(0xFF17191A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  formatDate(createdAt),
                  style: const TextStyle(
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w400,
                    fontSize: 12,
                    color: Color(0xFFA4ADB2),
                  ),
                ),
              ],
            ),
            if (content.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                content,
                style: const TextStyle(
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w400,
                  fontSize: 14,
                  color: Color(0xFF666666),
                  height: 1.5,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // 삭제 버튼
                GestureDetector(
                  onTap: () {
                    _showDeleteConfirmation(id, title, isEvent);
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
                // 수정 버튼 (아이템 클릭으로도 이동 가능)
                GestureDetector(
                  onTap: () async {
                    // 수정 화면에서 돌아올 때 true가 반환되면 목록 새로고침
                    final result = await context.push<bool>(
                      '/admin/notice-detail/$id?isEvent=${isEvent.toString()}',
                    );
                    if (result == true) {
                      if (isEvent) {
                        _loadEvents();
                      } else {
                        _loadNotices();
                      }
                    }
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
        // 정렬 변경 시 데이터 새로고침
        if (_tabController.index == 0) {
          _loadNotices();
        } else {
          _loadEvents();
        }
        Navigator.pop(context);
      },
    );
  }
}
