import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:building_manage_front/data/datasources/auth_remote_datasource.dart';
import 'package:building_manage_front/core/network/exceptions/api_exception.dart';

class ApiTestWidget extends ConsumerStatefulWidget {
  const ApiTestWidget({super.key});

  @override
  ConsumerState<ApiTestWidget> createState() => _ApiTestWidgetState();
}

class _ApiTestWidgetState extends ConsumerState<ApiTestWidget> {
  bool _isLoading = false;
  String? _result;

  Future<void> _testResidentRegister() async {
    setState(() {
      _isLoading = true;
      _result = null;
    });

    try {
      final authDataSource = ref.read(authRemoteDataSourceProvider);

      // 입주민 회원가입 테스트 (예시 데이터)
      final result = await authDataSource.registerResident(
        username: "resident123",
        password: "password123!",
        name: "홍길동",
        phoneNumber: "010-1234-5678",
        dong: "101동",
        hosu: "1001호",
        buildingId: "550e8400-e29b-41d4-a716-446655440000",
      );

      setState(() {
        _result = 'Success: ${result.toString()}';
      });
    } catch (e) {
      setState(() {
        if (e is ApiException) {
          _result = 'API Error: ${e.userFriendlyMessage}';
        } else {
          _result = 'Error: ${e.toString()}';
        }
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testManagerRegister() async {
    setState(() {
      _isLoading = true;
      _result = null;
    });

    try {
      final authDataSource = ref.read(authRemoteDataSourceProvider);

      // 관리자 회원가입 테스트 (예시 데이터)
      final result = await authDataSource.registerManager(
        managerCode: "MGR001",
        name: "김관리",
        phoneNumber: "010-9876-5432",
        buildingId: "550e8400-e29b-41d4-a716-446655440000",
      );

      setState(() {
        _result = 'Success: ${result.toString()}';
      });
    } catch (e) {
      setState(() {
        if (e is ApiException) {
          _result = 'API Error: ${e.userFriendlyMessage}';
        } else {
          _result = 'Error: ${e.toString()}';
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
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'API Test',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          ElevatedButton(
            onPressed: _isLoading ? null : _testResidentRegister,
            child: const Text('입주민 회원가입 테스트'),
          ),
          const SizedBox(height: 8),

          ElevatedButton(
            onPressed: _isLoading ? null : _testManagerRegister,
            child: const Text('관리자 회원가입 테스트'),
          ),
          const SizedBox(height: 16),

          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_result != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                _result!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                ),
              ),
            ),
        ],
      ),
    );
  }
}