import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:building_manage_front/modules/auth/presentation/providers/auth_state_provider.dart';
import 'package:building_manage_front/modules/admin/data/datasources/notice_remote_datasource.dart';
import 'package:building_manage_front/shared/widgets/custom_confirmation_dialog.dart'; // 삭제 확인 다이얼로그용
import 'package:building_manage_front/shared/widgets/error_alert.dart';
import 'package:building_manage_front/core/utils/error_message.dart';

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
  String? _loadError;

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
    // 화면이 열릴 때마다 데이터 새로고침
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNotices();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 화면이 다시 활성화될 때 데이터 새로고침
    final route = ModalRoute.of(context);
    if (route != null && route.isCurrent) {
      if (_tabController.index == 0) {
        _loadNotices();
      } else {
        _loadEvents();
      }
    }
  }

  void _onTabChanged() {
    if (_tabController.index == 0) {
      _loadNotices();
    } else {
      _loadEvents();
    }
  }

  Future<void> _loadNotices() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final noticeDataSource = ref.read(noticeRemoteDataSourceProvider);
      final response = await noticeDataSource.getNotices(
        sortOrder: _selectedFilter == '오래된순' ? 'ASC' : 'DESC',
      );

      if (mounted) {
        final noticeList = List<Map<String, dynamic>>.from(response['data']['data'] ?? []);
        setState(() {
          _notices = noticeList;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadError = userMessageOf(
              e,
              fallback: '공지사항을 불러오지 못했습니다.',
            ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final noticeDataSource = ref.read(noticeRemoteDataSourceProvider);
      final response = await noticeDataSource.getEvents(
        sortOrder: _selectedFilter == '오래된순' ? 'ASC' : 'DESC',
      );

      if (mounted) {
        // 이벤트 API 응답 구조: response["data"]["items"]
        final eventList = List<Map<String, dynamic>>.from(response['data']['items'] ?? []);
        setState(() {
          _events = eventList;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadError = userMessageOf(
              e,
              fallback: '이벤트를 불러오지 못했습니다.',
            ));
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
    // 이 자리는 건물명이다. 예전에는 User 에 건물명이 없어 관리자 이름(user.name)을
    // 임시로 넣고 TODO 를 달아 두었는데, 이후 로그인 응답의 building 객체에서
    // buildingName 을 채우게 되면서(User.fromJson) 그 전제가 사라졌다.
    // 고치지 않은 채로 남아 상단에 관리자 이름이 건물명처럼 표시되고 있었다.
    final buildingName = currentUser?.buildingName ?? '건물명';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
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
                height: 60,
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
                            labelPadding: const EdgeInsets.only(right: 32, top: 12, bottom: 12),
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
                      onPressed: () async {
                        final isEvent = _tabController.index == 1;
                        final result = await context.push<bool>(
                          '/admin/notice-create?isEvent=$isEvent',
                        );
                        // 등록 성공 시 목록 새로고침
                        if (result == true) {
                          if (isEvent) {
                            _loadEvents();
                          } else {
                            _loadNotices();
                          }
                        }
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
      // 하단 고정 버튼·마지막 목록 항목이 시스템 내비게이션 바에 가리지 않도록 감싼다.
      body: SafeArea(
        child: Column(
        children: [
          // 정렬 필터
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Color(0xFFE8EEF2),
                  width: 1,
                ),
              ),
            ),
            // 정렬 토글.
            //
            // 예전에는 Expanded 로 줄 전체를 차지하는 16px/w700 텍스트 하나였다.
            // 그 크기는 위쪽 탭 라벨과 같아서 정렬 값이 제목처럼 보였고, 누를 수 있다는
            // 신호가 전혀 없었다(테두리도 아이콘도 없음). 아래 칩 필터와 같은 형태로 줄여
            // '누르는 것' 으로 보이게 하고, 폭도 글자만큼만 차지하게 한다.
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    // 최신순 <-> 오래된순 토글
                    setState(() {
                      _selectedFilter =
                          _selectedFilter == '최신순' ? '오래된순' : '최신순';
                    });
                    // 정렬 변경 시 데이터 새로고침
                    if (_tabController.index == 0) {
                      _loadNotices();
                    } else {
                      _loadEvents();
                    }
                  },
                  // 정렬은 아래 필터 칩보다 한 단계 아래의 보조 조작이므로 더 작게 둔다.
                  // 다만 보이는 알약만 작게 하고, 바깥 여백으로 실제 터치 영역은 넉넉히 남긴다.
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0xFFE8EEF2),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _selectedFilter,
                            style: const TextStyle(
                              fontFamily: 'Pretendard',
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                              color: Color(0xFF757B80),
                            ),
                          ),
                          const SizedBox(width: 2),
                          // 눌러서 바뀌는 값임을 알리는 표시.
                          const Icon(
                            Icons.swap_vert,
                            size: 13,
                            color: Color(0xFF757B80),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 칩스 필터 (공지사항 탭에서만 표시)
          if (_tabController.index == 0)
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

    if (_loadError != null) {
      return _ListLoadError(message: _loadError!, onRetry: _loadNotices);
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
    // target 값에 따른 필터링:
    // - BOTH: 전체, 유저, 담당자 모두에서 보임
    // - RESIDENT: 유저와 전체 섹션에서만 보임
    // - STAFF: 담당자와 전체 섹션에서만 보임
    final filteredNotices = _notices.where((notice) {
      final target = notice['target'] as String?;

      if (_selectedChip == '전체') {
        // 전체 칩: BOTH, RESIDENT, STAFF 모두 표시
        return true;
      } else if (_selectedChip == '유저') {
        // 유저 칩: BOTH(전체)와 RESIDENT만 표시
        return target == 'RESIDENT' || target == 'BOTH';
      } else if (_selectedChip == '담당자') {
        // 담당자 칩: BOTH(전체)와 STAFF만 표시
        return target == 'STAFF' || target == 'BOTH';
      }
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

    if (_loadError != null) {
      return _ListLoadError(message: _loadError!, onRetry: _loadEvents);
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
    // target 값에 따른 필터링:
    // - BOTH: 전체, 유저, 담당자 모두에서 보임
    // - RESIDENT: 유저와 전체 섹션에서만 보임
    // - STAFF: 담당자와 전체 섹션에서만 보임
    final filteredEvents = _events.where((event) {
      final target = event['target'] as String?;

      if (_selectedChip == '전체') {
        // 전체 칩: BOTH, RESIDENT, STAFF 모두 표시
        return true;
      } else if (_selectedChip == '유저') {
        // 유저 칩: BOTH(전체)와 RESIDENT만 표시
        return target == 'RESIDENT' || target == 'BOTH';
      } else if (_selectedChip == '담당자') {
        // 담당자 칩: BOTH(전체)와 STAFF만 표시
        return target == 'STAFF' || target == 'BOTH';
      }
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
        // 목록 새로고침
        if (isEvent) {
          _loadEvents();
        } else {
          _loadNotices();
        }
      }
    } catch (e) {
      if (!mounted) return;
      await showErrorAlert(
        context,
        title: '삭제 실패',
        error: e,
        fallback: '삭제하지 못했습니다. 잠시 후 다시 시도해 주세요.',
      );
    }
  }

  Widget _buildNoticeItem(Map<String, dynamic> notice, {bool isEvent = false}) {
    final id = notice['id'] as String? ?? '';
    final rawTitle = notice['title'] as String? ?? '제목 없음';
    final target = notice['target'] as String? ?? 'BOTH';
    final departmentName = notice['department']?['name'] as String?;

    // 담당자 대상인 경우 앞에 부서명 추가
    final title = target == 'STAFF' && departmentName != null
        ? '[$departmentName] $rawTitle'
        : rawTitle;

    final content = notice['content'] as String? ?? '';
    final createdAt = notice['createdAt'] as String? ?? '';

    // 날짜 포맷팅 (ISO 8601 → 간단한 형식)
    String formatDate(String dateStr) {
      try {
        final date = DateTime.parse(dateStr).toLocal();
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

}

/// 목록 조회 실패 안내 + 재시도.
class _ListLoadError extends StatelessWidget {
  const _ListLoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onRetry,
            child: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }
}
