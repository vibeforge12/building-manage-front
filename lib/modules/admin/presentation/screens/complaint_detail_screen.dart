import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:building_manage_front/modules/admin/presentation/providers/admin_providers.dart';
import 'package:building_manage_front/modules/admin/domain/entities/complaint.dart';

class ComplaintDetailScreen extends ConsumerStatefulWidget {
  final String complaintId;

  const ComplaintDetailScreen({
    super.key,
    required this.complaintId,
  });

  @override
  ConsumerState<ComplaintDetailScreen> createState() => _ComplaintDetailScreenState();
}

class _ComplaintDetailScreenState extends ConsumerState<ComplaintDetailScreen> {
  late TextEditingController _responseController;
  String _selectedStatus = '';
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _responseController = TextEditingController();
  }

  @override
  void dispose() {
    _responseController.dispose();
    super.dispose();
  }

  Future<void> _updateComplaintStatus(String complaintId, String newStatus) async {
    final useCase = ref.read(updateComplaintStatusUseCaseProvider);

    setState(() => _isUpdating = true);

    try {
      await useCase.execute(
        complaintId: complaintId,
        status: newStatus,
        response: _responseController.text.isEmpty ? null : _responseController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('민원이 업데이트되었습니다.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('업데이트 실패: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  void _showStatusDialog(String currentStatus) {
    final statusOptions = ['PENDING', 'PROCESSING', 'COMPLETED', 'REJECTED'];
    final statusLabels = ['신규', '처리중', '완료', '반려'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('민원 상태 변경'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            statusOptions.length,
            (index) => RadioListTile(
              title: Text(statusLabels[index]),
              value: statusOptions[index],
              groupValue: currentStatus,
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedStatus = value);
                  context.pop();
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final getComplaintDetailUseCase = ref.watch(getComplaintDetailUseCaseProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF464A4D)),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          '민원 상세',
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: Color(0xFF464A4D),
          ),
        ),
      ),
      body: FutureBuilder(
        future: getComplaintDetailUseCase.execute(complaintId: widget.complaintId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF006FFF)),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Color(0xFFA4ADB2),
                  ),
                  const SizedBox(height: 16),
                  const Text('민원 정보를 불러올 수 없습니다.'),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: Text('데이터를 찾을 수 없습니다.'));
          }

          final complaint = snapshot.data as AdminComplaint;
          if (_selectedStatus.isEmpty) {
            _selectedStatus = complaint.status;
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with Status
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFE8EEF2), width: 1),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              complaint.title,
                              style: const TextStyle(
                                fontFamily: 'Pretendard',
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                                color: Color(0xFF17191A),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _getStatusColor(_selectedStatus),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _getStatusLabel(_selectedStatus),
                              style: const TextStyle(
                                fontFamily: 'Pretendard',
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.person, size: 16, color: Color(0xFFA4ADB2)),
                          const SizedBox(width: 4),
                          Text(
                            '${complaint.residentName} (${complaint.residentUnit})',
                            style: const TextStyle(
                              fontFamily: 'Pretendard',
                              fontWeight: FontWeight.w400,
                              fontSize: 14,
                              color: Color(0xFF757B80),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.category, size: 16, color: Color(0xFFA4ADB2)),
                          const SizedBox(width: 4),
                          Text(
                            complaint.departmentName,
                            style: const TextStyle(
                              fontFamily: 'Pretendard',
                              fontWeight: FontWeight.w400,
                              fontSize: 14,
                              color: Color(0xFF757B80),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 16, color: Color(0xFFA4ADB2)),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(complaint.createdAt),
                            style: const TextStyle(
                              fontFamily: 'Pretendard',
                              fontWeight: FontWeight.w400,
                              fontSize: 14,
                              color: Color(0xFFA4ADB2),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Image
                if (complaint.imageUrl != null && complaint.imageUrl!.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: complaint.imageUrl!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: 240,
                        placeholder: (context, url) => Container(
                          color: const Color(0xFFF2F8FC),
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: const Color(0xFFF2F8FC),
                          child: const Icon(Icons.error, color: Color(0xFFA4ADB2)),
                        ),
                      ),
                    ),
                  ),
                ],

                // Content
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '민원 내용',
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Color(0xFF17191A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        complaint.content,
                        style: const TextStyle(
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w400,
                          fontSize: 14,
                          color: Color(0xFF464A4D),
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(color: Color(0xFFE8EEF2), thickness: 1),

                // Status Update Section
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '처리 상태',
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Color(0xFF17191A),
                        ),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () => _showStatusDialog(_selectedStatus),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFE8EEF2)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _getStatusLabel(_selectedStatus),
                                style: const TextStyle(
                                  fontFamily: 'Pretendard',
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                  color: Color(0xFF17191A),
                                ),
                              ),
                              const Icon(Icons.arrow_drop_down, color: Color(0xFFA4ADB2)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '처리 내용',
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Color(0xFF17191A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _responseController,
                        maxLines: 5,
                        decoration: InputDecoration(
                          hintText: '처리 내용을 입력하세요.',
                          hintStyle: const TextStyle(
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w400,
                            fontSize: 14,
                            color: Color(0xFFA4ADB2),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFFE8EEF2)),
                          ),
                          contentPadding: const EdgeInsets.all(12),
                        ),
                      ),
                    ],
                  ),
                ),

                // Action Buttons
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isUpdating ? null : () => context.pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE8EEF2),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            '취소',
                            style: TextStyle(
                              fontFamily: 'Pretendard',
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: Color(0xFF757B80),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isUpdating ? null : () => _updateComplaintStatus(widget.complaintId, _selectedStatus),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF006FFF),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isUpdating
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text(
                                  '저장',
                                  style: TextStyle(
                                    fontFamily: 'Pretendard',
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return const Color(0xFFFF6B6B);
      case 'PROCESSING':
        return const Color(0xFF006FFF);
      case 'COMPLETED':
        return const Color(0xFF52C41A);
      case 'REJECTED':
        return const Color(0xFF999999);
      default:
        return const Color(0xFFE8EEF2);
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return '신규';
      case 'PROCESSING':
        return '처리중';
      case 'COMPLETED':
        return '완료';
      case 'REJECTED':
        return '반려';
      default:
        return '신규';
    }
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
