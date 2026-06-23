import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:building_manage_front/shared/widgets/field_label.dart';
import 'package:building_manage_front/shared/widgets/primary_action_button.dart';
import 'package:building_manage_front/shared/widgets/section_divider.dart';
import 'package:building_manage_front/shared/widgets/custom_confirmation_dialog.dart';
import 'package:building_manage_front/modules/manager/data/datasources/general_manager_remote_datasource.dart';

/// 총관리자(HEAD)가 자신의 건물에 일반관리자(GENERAL)를 추가하는 화면.
class AddGeneralManagerScreen extends ConsumerStatefulWidget {
  const AddGeneralManagerScreen({super.key});

  @override
  ConsumerState<AddGeneralManagerScreen> createState() => _AddGeneralManagerScreenState();
}

class _AddGeneralManagerScreenState extends ConsumerState<AddGeneralManagerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final dataSource = ref.read(generalManagerRemoteDataSourceProvider);
      await dataSource.createGeneralManager(
        name: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
      );

      if (mounted) {
        await showCustomConfirmationDialog(
          context: context,
          title: '',
          content: const Text(
            '일반관리자 계정이 발급되었습니다.',
            style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.w700),
          ),
          confirmText: '확인',
          cancelText: '',
          barrierDismissible: false,
          confirmOnLeft: true,
        );

        if (mounted) {
          await Future.delayed(const Duration(milliseconds: 200));
          if (mounted && context.canPop()) {
            context.pop();
          }
        }
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            icon: const Icon(Icons.error, color: Colors.red, size: 48),
            title: const Text('계정 발급 실패'),
            content: Text(e.toString().replaceAll('Exception: ', '')),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('확인'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
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
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            }
          },
        ),
        title: const Text(
          '일반관리자 추가',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: SectionDivider(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 안내 문구
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF5FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '같은 건물에 일반관리자를 추가합니다.\n관리자 코드와 임시 비밀번호는 입력한 번호로 문자 발송됩니다.',
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w400,
                    fontSize: 12,
                    color: Color(0xFF006FFF),
                    height: 1.5,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 이름 필드
              fieldLabel('이름', context),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: '이름을 입력해주세요',
                  hintStyle: TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: Color(0xFFF8F9FA),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '이름을 입력해주세요';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // 전화번호 필드
              fieldLabel('전화번호', context),
              const SizedBox(height: 8),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  hintText: '전화번호를 입력해주세요',
                  hintStyle: TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: Color(0xFFF8F9FA),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '전화번호를 입력해주세요';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                child: PrimaryActionButton(
                  label: _isSubmitting ? '발급 중...' : '일반관리자 추가',
                  backgroundColor: const Color(0xFF006FFF),
                  foregroundColor: Colors.white,
                  onPressed: _isSubmitting ? () {} : _submitForm,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
