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

  /// 펼쳐 놓은 묶음의 batchId.
  ///
  /// 다시 읽어도 유지한다. 묶음을 펼쳐 한 건물 것을 고치고 돌아오면 _load() 가 도는데,
  /// 이때 접혀 버리면 나머지 건물을 고치려고 매번 다시 펼쳐야 한다.
  final Set<String> _expandedBatches = <String>{};

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
          // 건물명이 길면 두 줄이 되어 AppBar 높이가 늘어난다. 한 줄로 자른다.
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
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

  /// 한 번에 여러 건물에 올린 공고문을 batchId 로 묶는다.
  ///
  /// 본사가 건물 5개를 골라 등록하면 건물마다 한 건씩 저장되므로 목록에 같은 제목이 5줄
  /// 생긴다. 관리하는 건물이 늘면 그대로 늘어나서, 목록에서 다른 공고문을 찾을 수 없게 된다.
  /// 묶어 두면 "무엇을 올렸는가" 는 한 줄이고, 건물별 수정·삭제는 펼쳐서 그대로 한다.
  ///
  /// 관리자·담당자에게는 자기 건물 것만 내려오므로 묶음이 대부분 1건이고 화면이 지금과 같다.
  List<List<Bulletin>> _groupByBatch() {
    final groups = <String, List<Bulletin>>{};
    final order = <String>[];
    for (final bulletin in _bulletins) {
      // batchId 가 비어 있으면(구버전 응답) 묶지 않고 각자 한 줄로 둔다.
      // 빈 문자열을 그대로 키로 쓰면 서로 무관한 공고문이 한 묶음이 된다.
      final key =
          bulletin.batchId.isEmpty ? 'single:${bulletin.id}' : bulletin.batchId;
      if (!groups.containsKey(key)) order.add(key);
      groups.putIfAbsent(key, () => <Bulletin>[]).add(bulletin);
    }
    return [for (final key in order) groups[key]!];
  }

  /// 지금 입주민에게 보이지 않는 공고문은 그 이유를 표시한다.
  /// 관리 화면에서 만료·예약·숨김이 구분되지 않으면 "왜 안 보이냐" 는 문의가 관리자에게 간다.
  (String?, Color) _badgeOf(Bulletin bulletin) => switch (bulletin) {
        _ when bulletin.status == BulletinStatus.hidden =>
          ('숨김', const Color(0xFF757B80)),
        _ when bulletin.isExpired => ('게시 종료', const Color(0xFFA4ADB2)),
        _ when bulletin.isScheduled => ('게시 예정', const Color(0xFF006FFF)),
        _ => (null, Colors.transparent),
      };

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Pretendard',
          fontWeight: FontWeight.w700,
          fontSize: 11,
          color: color,
        ),
      ),
    );
  }

  Widget _buildList(bool showBuildingName) {
    final groups = _groupByBatch();
    return RefreshIndicator(
      onRefresh: _load,
      color: const Color(0xFF006FFF),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: groups.length,
        // 서로 다른 공고문 사이는 '띠' 로 끊는다. 1px 실선으로는 어디까지가 한 건인지
        // 눈에 들어오지 않는다(묶음을 펼치면 줄이 여러 개가 되어 특히 그렇다).
        // 묶음 안의 건물별 줄은 실선으로만 나눠, 띠=다른 공고문 / 실선=같은 공고문이
        // 그대로 위계로 읽히게 한다.
        separatorBuilder: (context, index) =>
            const _ItemBand(),
        itemBuilder: (context, index) {
          final group = groups[index];
          return group.length == 1
              ? _buildItem(group.first, showBuildingName)
              : _buildGroup(group);
        },
      ),
    );
  }

  /// 여러 건물에 함께 올라간 공고문 한 묶음.
  ///
  /// 접힌 줄은 눌러도 수정 화면으로 가지 않는다. 어느 건물 것을 고칠지 정해지지 않아서다.
  /// 펼치면 건물별 줄이 나오고, 수정·삭제는 거기서 지금과 똑같이 한다.
  Widget _buildGroup(List<Bulletin> group) {
    final first = group.first;
    final isExpanded = _expandedBatches.contains(first.batchId);

    // 묶음 안에서 상태가 갈리면(한 건물만 숨김 등) 배지 하나로 요약할 수 없다.
    // 그때는 접힌 줄에 배지를 두지 않고 펼쳤을 때 건물별로 보게 한다.
    final distinctBadges = group.map((b) => _badgeOf(b).$1).toSet();
    final (String? badge, Color badgeColor) = distinctBadges.length == 1
        ? _badgeOf(first)
        : (null, Colors.transparent);

    // 게시 종료일도 수정으로 건물마다 달라질 수 있어, 모두 같을 때만 적는다.
    final sharedPostedUntil =
        group.every((b) => b.postedUntil == first.postedUntil)
            ? first.postedUntil
            : null;

    return Column(
      children: [
        InkWell(
          onTap: () => setState(() {
            if (isExpanded) {
              _expandedBatches.remove(first.batchId);
            } else {
              _expandedBatches.add(first.batchId);
            }
          }),
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
                            _buildBadge(badge, badgeColor),
                            const SizedBox(width: 6),
                          ],
                          Expanded(
                            child: Text(
                              first.title,
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
                          '${group.length}개 건물',
                          _formatDate(first.createdAt),
                          if (first.hasImages) '사진 ${first.imageUrls.length}장',
                          if (sharedPostedUntil != null)
                            '${_formatDate(sharedPostedUntil)}까지',
                          if (first.pushSent) '알림 발송됨',
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
                Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  size: 20,
                  color: const Color(0xFF757B80),
                ),
              ],
            ),
          ),
        ),
        if (isExpanded)
          // 펼친 줄은 건물별 공고문이므로 건물명을 반드시 함께 보여준다.
          for (int i = 0; i < group.length; i++) ...[
            if (i > 0)
              const Padding(
                padding: EdgeInsets.only(left: 32),
                child: Divider(height: 1, thickness: 1, color: Color(0xFFE1E9EF)),
              ),
            _buildItem(group[i], true, nested: true),
          ],
      ],
    );
  }

  Widget _buildItem(Bulletin bulletin, bool showBuildingName,
      {bool nested = false}) {
    final (String? badge, Color badgeColor) = _badgeOf(bulletin);

    return Container(
      // 펼친 줄은 배경과 들여쓰기로 묶음에 속한다는 것을 나타낸다.
      color: nested ? const Color(0xFFF7FAFC) : null,
      child: InkWell(
        onTap: bulletin.canManage ? () => _openEdit(bulletin.id) : null,
        child: Padding(
          padding: EdgeInsets.only(
            left: nested ? 32 : 16,
            right: 16,
            top: nested ? 12 : 14,
            bottom: nested ? 12 : 14,
          ),
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
                          _buildBadge(badge, badgeColor),
                          const SizedBox(width: 6),
                        ],
                        Expanded(
                          child: Text(
                            // 묶음 안에서는 제목이 이미 위에 있으므로 건물명을 제목 자리에 둔다.
                            nested
                                ? (bulletin.buildingName ?? bulletin.title)
                                : bulletin.title,
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
                        if (!nested &&
                            showBuildingName &&
                            bulletin.buildingName != null)
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
      ),
    );
  }
}

/// 목록에서 서로 다른 공고문을 끊어 주는 띠.
/// 실선 한 줄로는 묶음이 펼쳐졌을 때 경계가 묻혀서, 배경색 있는 간격으로 나눈다.
class _ItemBand extends StatelessWidget {
  const _ItemBand();

  @override
  Widget build(BuildContext context) {
    return Container(height: 8, color: const Color(0xFFF2F5F8));
  }
}
