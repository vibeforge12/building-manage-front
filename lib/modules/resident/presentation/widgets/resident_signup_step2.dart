import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/signup_form_provider.dart';
import 'package:building_manage_front/modules/common/data/datasources/building_list_remote_datasource.dart';

class ResidentSignupStep2 extends ConsumerStatefulWidget {
  final VoidCallback onPrevious;
  final VoidCallback onComplete;

  const ResidentSignupStep2({
    super.key,
    required this.onPrevious,
    required this.onComplete,
  });

  @override
  ConsumerState<ResidentSignupStep2> createState() => _ResidentSignupStep2State();
}

class _ResidentSignupStep2State extends ConsumerState<ResidentSignupStep2> {
  final _searchController = TextEditingController();

  List<Map<String, dynamic>> _buildings = [];
  List<Map<String, dynamic>> _filteredBuildings = [];
  Map<String, dynamic>? _selectedBuilding;
  bool _isLoadingBuildings = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadBuildings();

    // 선택된 건물이 있다면 설정
    final formData = ref.read(signupFormProvider);
    if (formData.buildingId != null) {
      _selectedBuilding = {'id': formData.buildingId};
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBuildings() async {
    setState(() {
      _isLoadingBuildings = true;
      _errorMessage = null;
    });

    try {
      final buildingDataSource = ref.read(buildingListRemoteDataSourceProvider);
      final response = await buildingDataSource.getBuildings(
        limit: 100, // 모든 건물을 가져오기 위해 큰 수로 설정
      );

      if (response['success'] == true) {
        final data = response['data'];
        final buildingsList = List<Map<String, dynamic>>.from(data['items'] ?? []);
        setState(() {
          _buildings = buildingsList;
          _filteredBuildings = buildingsList;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '건물 목록을 불러오는 중 오류가 발생했습니다.';
      });
    } finally {
      setState(() {
        _isLoadingBuildings = false;
      });
    }
  }

  void _filterBuildings(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredBuildings = _buildings;
      } else {
        _filteredBuildings = _buildings.where((building) {
          final name = building['name']?.toString().toLowerCase() ?? '';
          final address = building['address']?.toString().toLowerCase() ?? '';
          final searchQuery = query.toLowerCase();
          return name.contains(searchQuery) || address.contains(searchQuery);
        }).toList();
      }
    });
  }

  void _selectBuilding(Map<String, dynamic> building) {
    setState(() {
      _selectedBuilding = building;
      _searchController.clear();
      _filteredBuildings = _buildings;
    });
  }

  void _handleComplete() {
    if (_selectedBuilding == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('건물을 선택해주세요.')),
      );
      return;
    }

    // 선택된 건물 ID만 저장
    ref.read(signupFormProvider.notifier).updateStep2Data(
      username: '', // 3단계에서 입력받을 예정
      name: '', // 3단계에서 입력받을 예정
      phoneNumber: '', // 3단계에서 입력받을 예정
      buildingId: _selectedBuilding!['id'].toString(),
    );

    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 건물 검색
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _filterBuildings,
              decoration: const InputDecoration(
                hintText: '건물명을 입력해주세요',
                hintStyle: TextStyle(color: Colors.grey),
                prefixIcon: Icon(Icons.search, color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 건물 목록 표시
          if (_isLoadingBuildings)
            const Center(
              child: CircularProgressIndicator(),
            )
          else if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red[600]),
              ),
            )
          else if (_filteredBuildings.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  '검색 결과가 없습니다.',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: _filteredBuildings.length,
                itemBuilder: (context, index) {
                  final building = _filteredBuildings[index];
                  final isSelected = _selectedBuilding != null &&
                      _selectedBuilding!['id'] == building['id'];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue[50] : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? Colors.blue[200]! : Colors.grey[200]!,
                      ),
                    ),
                    child: InkWell(
                      onTap: () => _selectBuilding(building),
                      borderRadius: BorderRadius.circular(12),
                      child: Row(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.business,
                              color: Colors.blue,
                              size: 40,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  building['name'] ?? '건물명 없음',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  building['address'] ?? '주소 없음',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

          const SizedBox(height: 32),

          // 다음 버튼
          Container(
            width: double.infinity,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFE8EEF2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextButton(
              onPressed: _handleComplete,
              child: const Text(
                '다음',
                style: TextStyle(
                  color: Color(0xFFA4ADB2),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
        ),
      );
  }
}