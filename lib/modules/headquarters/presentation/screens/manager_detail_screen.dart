import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:building_manage_front/modules/common/data/datasources/manager_list_remote_datasource.dart';
import 'package:building_manage_front/core/network/exceptions/api_exception.dart';

class ManagerDetailScreen extends ConsumerStatefulWidget {
  final String managerId;

  const ManagerDetailScreen({
    super.key,
    required this.managerId,
  });

  @override
  ConsumerState<ManagerDetailScreen> createState() => _ManagerDetailScreenState();
}

class _ManagerDetailScreenState extends ConsumerState<ManagerDetailScreen> {
  Map<String, dynamic>? _managerData;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadManagerDetail();
  }

  Future<void> _loadManagerDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final managerDataSource = ref.read(managerListRemoteDataSourceProvider);
      final response = await managerDataSource.getManagerDetail(widget.managerId);

      if (response['success'] == true) {
        setState(() {
          _managerData = response['data'] as Map<String, dynamic>;
        });
      }
    } catch (e) {
      setState(() {
        if (e is ApiException) {
          _errorMessage = e.userFriendlyMessage;
        } else {
          _errorMessage = '관리자 정보를 불러오는 중 오류가 발생했습니다.';
        }
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final building = _managerData?['building'] as Map<String, dynamic>?;
    final buildingName = building?['name'] ?? '';

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
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(
            height: 1,
            thickness: 1,
            color: Color(0xFFE8EEF2),
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
                        onPressed: _loadManagerDetail,
                        child: const Text('다시 시도'),
                      ),
                    ],
                  ),
                )
              : _managerData == null
                  ? const Center(child: Text('관리자 정보를 찾을 수 없습니다.'))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 섹션 헤더
                        Container(
                          width: double.infinity,
                          height: 44,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          alignment: Alignment.centerLeft,
                          child: const Text(
                            '관리자',
                            style: TextStyle(
                              fontFamily: 'Pretendard',
                              fontWeight: FontWeight.w700,
                              fontSize: 20,
                              color: Color(0xFF17191A),
                            ),
                          ),
                        ),
                        // 정보 필드들
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInfoField(
                                label: '이름',
                                value: _managerData?['name'] ?? '',
                              ),
                              const SizedBox(height: 16),
                              _buildInfoField(
                                label: '전화번호',
                                value: _managerData?['phoneNumber'] ?? '',
                              ),
                              const SizedBox(height: 16),
                              _buildInfoField(
                                label: '관리자 코드',
                                value: _managerData?['managerCode'] ?? '',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
    );
  }

  Widget _buildInfoField({
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 라벨
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w400,
            fontSize: 12,
            color: Color(0xFF464A4D),
            height: 1.67,
          ),
        ),
        const SizedBox(height: 4),
        // 값 컨테이너
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: const Color(0xFFE8EEF2),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: const TextStyle(
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w400,
              fontSize: 16,
              color: Color(0xFF464A4D),
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}
