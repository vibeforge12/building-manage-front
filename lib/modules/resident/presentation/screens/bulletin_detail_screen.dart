import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:building_manage_front/modules/resident/data/datasources/bulletin_remote_datasource.dart';
import 'package:building_manage_front/modules/resident/domain/entities/bulletin.dart';

/// 공고문 상세.
///
/// 목록이 제목+날짜 한 줄이라, **사진이 실제로 보이는 곳은 여기뿐이다.**
/// 엘리베이터 게시판의 종이를 대신하는 화면이므로 사진을 크게 띄우고 확대까지 지원한다.
class BulletinDetailScreen extends ConsumerStatefulWidget {
  const BulletinDetailScreen({super.key, required this.bulletinId});

  final String bulletinId;

  @override
  ConsumerState<BulletinDetailScreen> createState() =>
      _BulletinDetailScreenState();
}

class _BulletinDetailScreenState extends ConsumerState<BulletinDetailScreen> {
  bool _isLoading = true;
  Bulletin? _bulletin;
  String? _error;
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _loadBulletin();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadBulletin() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final dataSource = ref.read(bulletinRemoteDataSourceProvider);
      final response =
          await dataSource.getBulletinDetail(bulletinId: widget.bulletinId);

      if (response['success'] == true && response['data'] != null) {
        if (mounted) {
          setState(() {
            _bulletin =
                Bulletin.fromJson(response['data'] as Map<String, dynamic>);
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _error = '공고문을 불러올 수 없습니다.';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('❌ Bulletin Detail Error: $e');
      if (mounted) {
        setState(() {
          // 서버는 접근 권한이 없거나 게시 기간이 지난 공고문도 404 로 답한다.
          // 이용자에게는 "없어진 글" 로 보이는 것이 맞다.
          _error = '공고문을 찾을 수 없습니다.';
          _isLoading = false;
        });
      }
    }
  }

  String _formatDate(DateTime date) => DateFormat('yyyy.MM.dd').format(date);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildNavigationBar(),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xFF006FFF)),
                      ),
                    )
                  : _error != null || _bulletin == null
                      ? _buildErrorState()
                      : _buildContent(_bulletin!),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationBar() {
    return Container(
      height: 48,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE8EEF2), width: 1),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, size: 24),
            onPressed: () => context.pop(),
            padding: const EdgeInsets.all(12),
          ),
          const Expanded(
            child: Align(
              alignment: Alignment.center,
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
          ),
          const SizedBox(width: 48),
        ],
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
            _error ?? '공고문을 찾을 수 없습니다.',
            style: const TextStyle(
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

  Widget _buildContent(Bulletin bulletin) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12, left: 16),
            child: Text(
              '작성일 : ${_formatDate(bulletin.createdAt)}',
              style: const TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w400,
                fontSize: 12,
                color: Color(0xFF757B80),
              ),
            ),
          ),
          Container(
            height: 1,
            color: const Color(0xFFE8EEF2),
            margin: const EdgeInsets.only(top: 12),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bulletin.title,
                  style: const TextStyle(
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    color: Color(0xFF17191A),
                    height: 1.25,
                  ),
                ),

                // 게시 종료가 정해져 있으면 알려준다. 종이 공고문과 달리 언제 내려가는지
                // 보이지 않으면, 입주민은 지난 공고를 계속 유효한 것으로 착각한다.
                if (bulletin.postedUntil != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${_formatDate(bulletin.postedUntil!)} 까지 게시',
                    style: const TextStyle(
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                      color: Color(0xFF006FFF),
                    ),
                  ),
                ],

                const SizedBox(height: 16),
                Container(height: 1, color: const Color(0xFFE8EEF2)),
                const SizedBox(height: 24),

                // 본문은 없을 수 있다(이미지만 있는 공고문).
                if (bulletin.content?.trim().isNotEmpty == true) ...[
                  Text(
                    bulletin.content!,
                    style: const TextStyle(
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w400,
                      fontSize: 16,
                      color: Color(0xFF464A4D),
                      height: 1.8,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ],
            ),
          ),

          if (bulletin.hasImages) _buildImageSection(bulletin),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  /// 사진 영역.
  ///
  /// 높이를 고정하지 않고 화면 폭 기준 4:3 으로 잡는다. 공고문 사진은 대개 세로로 긴
  /// A4 게시물이라, 고정 높이를 주면 글자가 읽을 수 없을 만큼 작아진다.
  /// 그래도 부족하면 탭해서 전체화면으로 확대할 수 있다.
  Widget _buildImageSection(Bulletin bulletin) {
    final images = bulletin.imageUrls;

    return Column(
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.width * 4 / 3,
          child: PageView.builder(
            controller: _pageController,
            itemCount: images.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) => GestureDetector(
              onTap: () => _openViewer(images, index),
              child: CachedNetworkImage(
                imageUrl: images[index],
                fit: BoxFit.contain,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFF006FFF)),
                  ),
                ),
                errorWidget: (context, url, error) => const Center(
                  child: Icon(
                    Icons.broken_image_outlined,
                    size: 40,
                    color: Color(0xFF757B80),
                  ),
                ),
              ),
            ),
          ),
        ),

        // 사진이 2장 이상일 때만 페이지 표시. 1장이면 점 하나가 떠서 오히려 헷갈린다.
        if (images.length > 1) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (int i = 0; i < images.length; i++)
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i == _currentPage
                        ? const Color(0xFF006FFF)
                        : const Color(0xFFE8EEF2),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${_currentPage + 1} / ${images.length}',
            style: const TextStyle(
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w400,
              fontSize: 13,
              color: Color(0xFF757B80),
            ),
          ),
        ],
      ],
    );
  }

  void _openViewer(List<String> images, int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => _BulletinImageViewer(
          images: images,
          initialIndex: initialIndex,
        ),
      ),
    );
  }
}

/// 전체화면 사진 뷰어. 확대·좌우 넘김을 지원한다.
class _BulletinImageViewer extends StatefulWidget {
  const _BulletinImageViewer({
    required this.images,
    required this.initialIndex,
  });

  final List<String> images;
  final int initialIndex;

  @override
  State<_BulletinImageViewer> createState() => _BulletinImageViewerState();
}

class _BulletinImageViewerState extends State<_BulletinImageViewer> {
  late final PageController _controller =
      PageController(initialPage: widget.initialIndex);
  late int _index = widget.initialIndex;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _controller,
              itemCount: widget.images.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, i) => InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: Center(
                  child: CachedNetworkImage(
                    imageUrl: widget.images[i],
                    fit: BoxFit.contain,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    errorWidget: (context, url, error) => const Icon(
                      Icons.broken_image_outlined,
                      size: 48,
                      color: Colors.white54,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            if (widget.images.length > 1)
              Positioned(
                bottom: 24,
                left: 0,
                right: 0,
                child: Text(
                  '${_index + 1} / ${widget.images.length}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
