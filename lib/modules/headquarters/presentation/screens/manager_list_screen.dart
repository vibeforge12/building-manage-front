import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:building_manage_front/modules/common/data/datasources/manager_list_remote_datasource.dart';
import 'package:building_manage_front/core/network/exceptions/api_exception.dart';

class ManagerListScreen extends ConsumerStatefulWidget {
  const ManagerListScreen({super.key});

  @override
  ConsumerState<ManagerListScreen> createState() => _ManagerListScreenState();
}

class _ManagerListScreenState extends ConsumerState<ManagerListScreen> {
  List<Map<String, dynamic>> _managers = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadManagers();
  }

  Future<void> _loadManagers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final managerDataSource = ref.read(managerListRemoteDataSourceProvider);
      final response = await managerDataSource.getManagers(
        limit: 100,
        sortOrder: 'DESC',
      );

      if (response['success'] == true) {
        final data = response['data'];
        setState(() {
          _managers = List<Map<String, dynamic>>.from(data['data'] ?? []);
        });
      }
    } catch (e) {
      setState(() {
        if (e is ApiException) {
          _errorMessage = e.userFriendlyMessage;
        } else {
          _errorMessage = '관리자 목록을 불러오는 중 오류가 발생했습니다.';
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
          '관리자',
          style: TextStyle(
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
                        onPressed: _loadManagers,
                        child: const Text('다시 시도'),
                      ),
                    ],
                  ),
                )
              : _managers.isEmpty
                  ? const Center(
                      child: Text(
                        '등록된 관리자가 없습니다.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : _buildManagerList(),
    );
  }

  Widget _buildManagerList() {
    // 건물별로 관리자 그룹화
    final Map<String, List<Map<String, dynamic>>> groupedManagers = {};

    for (final manager in _managers) {
      final building = manager['building'] as Map<String, dynamic>?;
      final buildingName = building?['name'] ?? '건물명 없음';

      if (!groupedManagers.containsKey(buildingName)) {
        groupedManagers[buildingName] = [];
      }
      groupedManagers[buildingName]!.add(manager);
    }

    return ListView.builder(
      itemCount: groupedManagers.length,
      itemBuilder: (context, index) {
        final buildingName = groupedManagers.keys.elementAt(index);
        final managers = groupedManagers[buildingName]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 건물명 섹션 헤더
            Container(
              width: double.infinity,
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.centerLeft,
              child: Text(
                buildingName,
                style: const TextStyle(
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  color: Color(0xFF17191A),
                ),
              ),
            ),
            // 관리자 리스트
            ...managers.map((manager) => _buildManagerItem(manager)),
            // 구분선
            Container(
              width: double.infinity,
              height: 8,
              color: const Color(0xFFF2F8FC),
            ),
          ],
        );
      },
    );
  }

  Widget _buildManagerItem(Map<String, dynamic> manager) {
    final name = manager['name'] ?? '이름 없음';
    final managerId = manager['id']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Row(
        children: [
          // 관리자 이름
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: Color(0xFF17191A),
              ),
            ),
          ),
          // 상세보기 아이콘
          GestureDetector(
            onTap: () {
              context.push('/headquarters/manager-detail/$managerId');
            },
            child: const Icon(
              Icons.chevron_right,
              size: 24,
              color: Color(0xFF464A4D),
            ),
          ),
        ],
      ),
    );
  }
}
