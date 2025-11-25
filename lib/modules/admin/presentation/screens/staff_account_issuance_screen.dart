import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:building_manage_front/modules/admin/presentation/providers/department_provider.dart';
import 'package:building_manage_front/modules/admin/presentation/providers/staff_provider.dart';
import 'package:building_manage_front/shared/widgets/custom_confirmation_dialog.dart';

/// 담당자 계정발급 화면
class StaffAccountIssuanceScreen extends ConsumerStatefulWidget {
  const StaffAccountIssuanceScreen({super.key});

  @override
  ConsumerState<StaffAccountIssuanceScreen> createState() =>
      _StaffAccountIssuanceScreenState();
}

class _StaffAccountIssuanceScreenState
    extends ConsumerState<StaffAccountIssuanceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  String? _selectedDepartment;
  String? _selectedDepartmentId;

  @override
  void initState() {
    super.initState();
    // 화면 로드 시 부서 목록 불러오기
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(departmentListProvider.notifier).fetchDepartments();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  bool get _isFormValid {
    return _nameController.text.trim().isNotEmpty &&
        _phoneController.text.trim().isNotEmpty &&
        _selectedDepartment != null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 이름 입력
                _buildTextField(
                  label: '이름',
                  placeholder: '이름을 입력해주세요.',
                  controller: _nameController,
                ),
                const SizedBox(height: 16),

                // 전화번호 입력
                _buildTextField(
                  label: '전화번호',
                  placeholder: '전화번호를 입력해주세요',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),

                // 담당부서 선택
                _buildDepartmentSelect(),
                const SizedBox(height: 32),

                // 계정발급 버튼
                _buildSubmitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back,
          color: Color(0xFF464A4D),
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: const Text(
        '담당자 계정발급',
        style: TextStyle(
          fontFamily: 'Pretendard',
          fontWeight: FontWeight.w700,
          fontSize: 16,
          height: 1.5,
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
    );
  }

  Widget _buildTextField({
    required String label,
    required String placeholder,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w400,
            fontSize: 12,
            height: 1.67,
            color: Color(0xFF464A4D),
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: const TextStyle(
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w400,
              fontSize: 16,
              height: 1.5,
              color: Color(0xFFA4ADB2),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Color(0xFFE8EEF2),
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Color(0xFFE8EEF2),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Color(0xFF006FFF),
                width: 1,
              ),
            ),
          ),
          style: const TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w400,
            fontSize: 16,
            height: 1.5,
            color: Color(0xFF464A4D),
          ),
        ),
      ],
    );
  }

  Widget _buildDepartmentSelect() {
    final departmentState = ref.watch(departmentListProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '담당부서',
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w400,
            fontSize: 12,
            height: 1.67,
            color: Color(0xFF464A4D),
          ),
        ),
        const SizedBox(height: 4),
        departmentState.isLoading
            ? Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(
                    color: const Color(0xFFE8EEF2),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : DropdownMenu<String>(
                initialSelection: _selectedDepartmentId,
                width: MediaQuery.of(context).size.width - 32,
                menuHeight: 300,
                requestFocusOnTap: true,
                enableFilter: false,
                menuStyle: MenuStyle(
                  backgroundColor: WidgetStateProperty.all(Colors.white),
                  surfaceTintColor: WidgetStateProperty.all(Colors.white),
                  elevation: WidgetStateProperty.all(8),
                  shape: WidgetStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                textStyle: const TextStyle(
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w400,
                  fontSize: 16,
                  color: Color(0xFF464A4D),
                ),
                inputDecorationTheme: InputDecorationTheme(
                  filled: true,
                  fillColor: Colors.white,
                  hintStyle: const TextStyle(
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w400,
                    fontSize: 16,
                    color: Color(0xFFA4ADB2),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Color(0xFFE8EEF2),
                      width: 1,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Color(0xFFE8EEF2),
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Color(0xFF006FFF),
                      width: 1,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                ),
                trailingIcon: const Icon(
                  Icons.keyboard_arrow_down,
                  size: 20,
                  color: Color(0xFF464A4D),
                ),
                selectedTrailingIcon: const Icon(
                  Icons.keyboard_arrow_up,
                  size: 20,
                  color: Color(0xFF006FFF),
                ),
                dropdownMenuEntries: departmentState.departments.map((dept) {
                  return DropdownMenuEntry<String>(
                    value: dept['id'] as String,
                    label: dept['name'] as String,
                    style: MenuItemButton.styleFrom(
                      foregroundColor: const Color(0xFF464A4D),
                      backgroundColor: Colors.white,
                      textStyle: const TextStyle(
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w400,
                        fontSize: 16,
                      ),
                    ),
                  );
                }).toList(),
                onSelected: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedDepartmentId = value;
                      _selectedDepartment = departmentState.departments
                          .firstWhere((dept) => dept['id'] == value)['name'];
                    });
                  }
                },
              ),
        if (departmentState.error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              departmentState.error!,
              style: const TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 12,
                color: Colors.red,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    final staffState = ref.watch(staffAccountIssuanceProvider);
    final isEnabled = _isFormValid && !staffState.isLoading;

    return SizedBox(
      height: 56,
      child: FilledButton(
        onPressed: isEnabled ? _handleSubmit : null,
        style: FilledButton.styleFrom(
          backgroundColor: isEnabled
              ? const Color(0xFF006FFF)
              : const Color(0xFF006FFF),
          disabledBackgroundColor: const Color(0xFF006FFF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(16),
        ),
        child: staffState.isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                '계정발급',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  height: 1.5,
                  color: isEnabled ? Colors.white : Colors.white.withOpacity(0.5),
                ),
              ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    if (_selectedDepartmentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('담당부서를 선택해주세요.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Provider를 통해 계정 발급 요청
    await ref.read(staffAccountIssuanceProvider.notifier).createStaffAccount(
      name: _nameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      departmentId: _selectedDepartmentId!,
    );

    if (!mounted) return;

    final staffState = ref.read(staffAccountIssuanceProvider);

    if (staffState.isSuccess) {
      // 성공 모달 표시
      if (mounted) {
        await showCustomConfirmationDialog(
          context: context,
          title: '',
          content: const Text(
            '담당자 계정이 발급되었습니다.',
            style: TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          confirmText: '확인',
          cancelText: '',
          barrierDismissible: false,
          confirmOnLeft: true,
        );

        if (mounted) {
          context.go('/admin/dashboard');
        }
      }
    } else if (staffState.error != null) {
      // 에러 메시지 표시
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(staffState.error!),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}