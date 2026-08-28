import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:building_manage_front/core/utils/error_message.dart';
import 'package:building_manage_front/modules/admin/data/datasources/bulletin_remote_datasource.dart';
import 'package:building_manage_front/modules/auth/presentation/providers/auth_state_provider.dart';
import 'package:building_manage_front/modules/resident/domain/entities/bulletin.dart';
import 'package:building_manage_front/core/constants/user_types.dart';
import 'package:building_manage_front/shared/widgets/custom_confirmation_dialog.dart';
import 'package:building_manage_front/shared/widgets/error_alert.dart';

/// 공고문 관리 목록. 본사·관리자·담당자가 함께 쓴다.
///
/// 역할별로 화면을 나누지 않는 이유는, 세 역할이 하는 일이 같고 다른 것은 "무엇을 볼 수
/// 있고 무엇을 고칠 수 있는가" 뿐이기 때문이다. 그 판단은 서버가 이미 하고 있다 —
/// 목록에는 볼 수 있는 것만 오고, 각 건의 canManage 로 수정·삭제 가능 여부가 온다.
/// 화면을 셋으로 나누면 같은 규칙을 세 곳에 적어야 하고 언젠가 서로 어긋난다.
///
/// 입주민 목록과 달리 숨김·기간만료 공고문까지 함께 보여준다. 지난 공고문을 다시 꺼내
/// 지우거나 기간을 늘리려면 목록에 나와야 한다.
class BulletinManagementScreen extends ConsumerStatefulWidget {
  const BulletinManagementScreen({super.key});

  @override
  ConsumerState<BulletinManagementScreen> createState() =>
      _BulletinManagementScreenState();
}

class _BulletinManagementScreenState
    extends ConsumerState<BulletinManagementScreen> {
  bool _isLoading = true;
  List<Bulletin> _bulletins = [];
  String? _loadError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  /// 등록·수정 화면으로 이동하고, 실제로 바뀐 경우에만 목록을 다시 읽는다.
  ///
  /// didChangeDependencies 로 매번 갱신하지 않는 이유는, 그러면 화면이 다시 보일 때마다
  /// 조건 없이 재조회가 돌기 때문이다. 이 저장소의 공지 관리 화면도 결과값으로 판단한다.
  Future<void> _openCreate() async {
    final changed = await context.pushNamed<bool>('bulletinCreate');
    if (changed == true && mounted) _load();
  }

  Future<void> _openEdit(String bulletinId) async {
    final changed = await context.pushNamed<bool>(
      'bulletinEdit',
      pathParameters: {'bulletinId': bulletinId},
    );
    if (changed == true && mounted) _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final dataSource = ref.read(adminBulletinRemoteDataSourceProvider);
      final response = await dataSource.getBulletins(includeInactive: true);
      if (!mounted) return;
      setState(() {
        _bulletins = _extractItems(response['data'])
            .map((json) => Bulletin.fromJson(json))
            .toList();
      });
    } catch (e) {
      if (mounted) {
        setState(() => _loadError =
            userMessageOf(e, fallback: '공고문을 불러오지 못했습니다.'));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> _extractItems(dynamic data) {
    if (data is List) return data.cast<Map<String, dynamic>>();
    if (data is Map) {
      final items = data['data'] ?? data['items'];
      if (items is List) return items.cast<Map<String, dynamic>>();
    }
    return const [];
  }

  Future<void> _confirmDelete(Bulletin bulletin) async {
    final result = await showCustomConfirmationDialog(
      context: context,
      title: '공고문을 삭제하시겠습니까?',
      content: const SizedBox.shrink(),
      confirmText: '예',
      cancelText: '아니요',
      isDestructive: true,
    );
    if (result != true) return;

    try {
      final dataSource = ref.read(adminBulletinRemoteDataSourceProvider);
      await dataSource.deleteBulletin(bulletin.id);
      if (mounted) _load();
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

  String _formatDate(DateTime date) => DateFormat('yyyy.MM.dd').format(date);

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final isHeadquarters = currentUser?.userType == UserType.headquarters;

    // 상단 제목은 공지사항 관리 화면과 같이 '건물명' 이다.
    // 본사는 특정 건물에 속하지 않아 buildingName 이 비어 있으므로, 그때는
    // 산하 전체를 보고 있다는 뜻으로 표시한다. ('건물명' 같은 자리표시자를 그대로
    // 내보내면 공지 관리 화면에 있던 것과 같은 종류의 버그가 된다)
    final headerTitle = isHeadquarters
        ? '전체 건물'
        : (currentUser?.buildingName ?? '공고문 관리');

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
          headerTitle,
          style: const TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: Color(0xFF464A4D),
          ),
        ),
        centerTitle: true,
        // 공지사항 관리 화면과 같은 자리에 '무엇을 보고 있는지' 와 등록 버튼을 둔다.
        // 그쪽은 이 줄에 탭(공지사항/이벤트)이 들어가고, 공고문은 탭이 없어 이름만 적는다.
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(55),
          child: Column(
            children: [
              Container(height: 1, color: const Color(0xFFE8EEF2)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                height: 60,
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        '공고문',
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Color(0xFF17191A),
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _openCreate,
                      icon: const Icon(Icons.add, size: 20, color: Colors.white),
                      label: const Text(
                        '공고문 등록',
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFF006FFF),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 8),
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
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF006FFF)),
                ),
              )
            : _loadError != null
                ? _buildErrorState()
                : _bulletins.isEmpty
                    ? _buildEmptyState()
                    // 본사는 여러 건물의 공고문을 함께 보므로 각 줄에 건물명을 덧붙인다.
                    // 관리자·담당자는 자기 건물뿐이라 같은 이름이 반복되면 잡음이 된다.
                    : _buildList(isHeadquarters),
      ),
    );
  }


  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Color(0xFF757B80)),
          const SizedBox(height: 16),
          Text(
            _loadError!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w400,
              fontSize: 14,
              color: Color(0xFF757B80),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _load,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF006FFF),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              '다시 시도',
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.campaign_outlined, size: 48, color: Color(0xFF757B80)),
          SizedBox(height: 16),
          Text(
            '등록된 공고문이 없습니다.',
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w400,
              fontSize: 14,
              color: Color(0xFF757B80),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(bool showBuildingName) {
    return RefreshIndicator(
      onRefresh: _load,
      color: const Color(0xFF006FFF),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _bulletins.length,
        separatorBuilder: (context, index) =>
            const Divider(height: 1, color: Color(0xFFE8EEF2)),
        itemBuilder: (context, index) =>
            _buildItem(_bulletins[index], showBuildingName),
      ),
    );
  }

  Widget _buildItem(Bulletin bulletin, bool showBuildingName) {
    // 지금 입주민에게 보이지 않는 공고문은 그 이유를 표시한다.
    // 관리 화면에서 만료·예약·숨김이 구분되지 않으면 "왜 안 보이냐" 는 문의가 관리자에게 간다.
    final (String? badge, Color badgeColor) = switch (bulletin) {
      _ when bulletin.status == BulletinStatus.hidden => ('숨김', const Color(0xFF757B80)),
      _ when bulletin.isExpired => ('게시 종료', const Color(0xFFA4ADB2)),
      _ when bulletin.isScheduled => ('게시 예정', const Color(0xFF006FFF)),
      _ => (null, Colors.transparent),
    };

    return InkWell(
      onTap: bulletin.canManage ? () => _openEdit(bulletin.id) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (badge != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: badgeColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            badge,
                            style: TextStyle(
                              fontFamily: 'Pretendard',
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                              color: badgeColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Expanded(
                        child: Text(
                          bulletin.title,
                          style: const TextStyle(
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                            color: Color(0xFF17191A),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    [
                      if (showBuildingName && bulletin.buildingName != null)
                        bulletin.buildingName!,
                      _formatDate(bulletin.createdAt),
                      if (bulletin.hasImages) '사진 ${bulletin.imageUrls.length}장',
                      if (bulletin.postedUntil != null)
                        '${_formatDate(bulletin.postedUntil!)}까지',
                      if (bulletin.pushSent) '알림 발송됨',
                    ].join('  ·  '),
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
            // 수정·삭제는 서버가 내려준 canManage 로만 노출한다.
            // 담당자는 자기가 올린 것만 고칠 수 있어서, 같은 건물 목록에도 못 고치는 건이 섞인다.
            if (bulletin.canManage)
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    size: 20, color: Color(0xFF757B80)),
                onPressed: () => _confirmDelete(bulletin),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              ),
          ],
        ),
      ),
    );
  }
}
