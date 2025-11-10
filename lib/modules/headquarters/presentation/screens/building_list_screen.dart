import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:building_manage_front/modules/common/data/datasources/building_list_remote_datasource.dart';
import 'package:building_manage_front/core/network/exceptions/api_exception.dart';
import 'package:building_manage_front/shared/widgets/custom_confirmation_dialog.dart';

class BuildingListScreen extends ConsumerStatefulWidget {
  const BuildingListScreen({super.key});

  @override
  ConsumerState<BuildingListScreen> createState() => _BuildingListScreenState();
}

class _BuildingListScreenState extends ConsumerState<BuildingListScreen> {
  List<Map<String, dynamic>> _buildings = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadBuildings();
  }

  Future<void> _loadBuildings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final buildingDataSource = ref.read(buildingListRemoteDataSourceProvider);
      final response = await buildingDataSource.getBuildings(
        limit: 100,
        sortOrder: 'DESC',
      );

      if (response['success'] == true) {
        final data = response['data'];
        setState(() {
          _buildings = List<Map<String, dynamic>>.from(data['items'] ?? []);
        });
      }
    } catch (e) {
      setState(() {
        if (e is ApiException) {
          _errorMessage = e.userFriendlyMessage;
        } else {
          _errorMessage = '건물 목록을 불러오는 중 오류가 발생했습니다.';
        }
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteBuilding(String buildingId, String buildingName) async {
    // 삭제 확인 다이얼로그
    final confirmed = await showCustomConfirmationDialog(
      context: context,
      title: '삭제를 진행하시겠습니까?',
      content: const SizedBox.shrink(), // 본문 없이 제목만 중앙 굵게
      confirmText: '예',
      cancelText: '아니오',
      confirmOnLeft: true,     // ← 이미지처럼 "예"를 왼쪽에
      barrierDismissible: false,
    );


    if (confirmed != true) return;

    try {
      final buildingDataSource = ref.read(buildingListRemoteDataSourceProvider);
      final response = await buildingDataSource.deleteBuilding(buildingId);

      if (response['success'] == true) {
        // 성공 메시지 표시
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('건물이 삭제되었습니다.'),
              backgroundColor: Colors.green,
            ),
          );
          // 목록 새로고침
          _loadBuildings();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is ApiException
                  ? e.userFriendlyMessage
                  : '건물 삭제 중 오류가 발생했습니다.',
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
          '건물 관리',
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: Color(0xFF464A4D),
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {
              context.push('/headquarters/building-registration');
            },
            child: const Text(
              '등록',
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: Color(0xFF464A4D),
              ),
            ),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(
            height: 1,
            thickness: 1,
            color: Color(0xFFE8EEF2),
            // margin: EdgeInsets.zero,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadBuildings,
                        child: const Text('다시 시도'),
                      ),
                    ],
                  ),
                )
              : _buildings.isEmpty
                  ? const Center(
                      child: Text(
                        '등록된 건물이 없습니다.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _buildings.length,
                      itemBuilder: (context, index) {
                        final building = _buildings[index];
                        final buildingId = building['id']?.toString() ?? '';
                        final buildingName = building['name'] ?? '건물명 없음';

                        return _BuildingItem(
                          building: building,
                          onDelete: () {
                            if (buildingId.isNotEmpty) {
                              _deleteBuilding(buildingId, buildingName);
                            }
                          },
                          onEdit: () {
                            // TODO: 등록(수정) 기능
                          },
                        );
                      },
                    ),
    );
  }
}

class _BuildingItem extends StatelessWidget {
  final Map<String, dynamic> building;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _BuildingItem({
    required this.building,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final name = building['name'] ?? '건물명 없음';
    final address = building['address'] ?? '주소 없음';
    final imageUrl = building['imageUrl'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 이미지
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFFE8EEF2),
                width: 1,
              ),
            ),
            child: imageUrl != null && imageUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.business,
                          size: 32,
                          color: Color(0xFFBDBDBD),
                        );
                      },
                    ),
                  )
                : const Icon(
                    Icons.business,
                    size: 32,
                    color: Color(0xFFBDBDBD),
                  ),
          ),
          const SizedBox(width: 16),
          // 건물명과 주소
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Color(0xFF17191A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  address,
                  style: const TextStyle(
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w400,
                    fontSize: 12,
                    color: Color(0xFF757B80),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // 버튼들
          Row(
            children: [
              // 삭제 버튼
              InkWell(
                onTap: onDelete,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFE8EEF2),
                      width: 1,
                    ),
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
              // const SizedBox(width: 8),
              // // 등록 버튼
              // InkWell(
              //   onTap: onEdit,
              //   borderRadius: BorderRadius.circular(8),
              //   child: Container(
              //     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              //     decoration: BoxDecoration(
              //       color: const Color(0xFFEDF9FF),
              //       borderRadius: BorderRadius.circular(8),
              //     ),
              //     child: const Text(
              //       '등록',
              //       style: TextStyle(
              //         fontFamily: 'Pretendard',
              //         fontWeight: FontWeight.w700,
              //         fontSize: 12,
              //         color: Color(0xFF0683FF),
              //       ),
              //     ),
              //   ),
              // ),
            ],
          ),
        ],
      ),
    );
  }
}
