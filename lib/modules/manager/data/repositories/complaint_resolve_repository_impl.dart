import 'package:building_manage_front/modules/manager/domain/repositories/complaint_resolve_repository.dart';
import 'package:building_manage_front/modules/manager/data/datasources/staff_complaints_remote_datasource.dart';

class ComplaintResolveRepositoryImpl implements ComplaintResolveRepository {
  final StaffComplaintsRemoteDataSource _dataSource;

  ComplaintResolveRepositoryImpl(this._dataSource);

  @override
  Future<Map<String, dynamic>> resolveComplaint({
    required String complaintId,
    required String content,
    String? imageUrl,
  }) async {
    return await _dataSource.resolveComplaint(
      complaintId: complaintId,
      content: content,
      imageUrl: imageUrl,
    );
  }
}
