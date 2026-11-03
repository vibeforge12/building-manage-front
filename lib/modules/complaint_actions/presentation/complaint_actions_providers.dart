import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../auth/presentation/providers/auth_state_provider.dart';
import '../data/complaint_actions_remote_datasource.dart';
import '../data/complaint_actions_repository_impl.dart';
import '../domain/entities/complaint_actions.dart';
import '../domain/usecases/complaint_actions_use_case.dart';

final complaintActionsUseCaseProvider = Provider<ComplaintActionsUseCase>(
  (ref) => ComplaintActionsUseCase(
    ComplaintActionsRepositoryImpl(
      ComplaintActionsRemoteDataSource(ref.watch(apiClientProvider)),
    ),
  ),
);

final complaintActionsProvider = FutureProvider.autoDispose
    .family<ComplaintActions, String>((ref, id) {
      ref.watch(authStateProvider);
      return ref.watch(complaintActionsUseCaseProvider).load(id);
    });
