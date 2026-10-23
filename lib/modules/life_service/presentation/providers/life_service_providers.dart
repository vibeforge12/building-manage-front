import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:building_manage_front/core/network/api_client.dart';
import '../../data/datasources/life_service_remote_datasource.dart';
import '../../data/repositories/life_service_repository_impl.dart';
import '../../domain/usecases/life_service_use_cases.dart';
import 'package:image_picker/image_picker.dart';

final lifeServiceImagePickerProvider = Provider<ImagePicker>(
  (ref) => ImagePicker(),
);

final lifeServiceRemoteDataSourceProvider =
    Provider<LifeServiceRemoteDataSource>(
      (ref) => LifeServiceRemoteDataSource(ref.read(apiClientProvider)),
    );
final lifeServiceRepositoryProvider = Provider<LifeServiceRepositoryImpl>(
  (ref) =>
      LifeServiceRepositoryImpl(ref.read(lifeServiceRemoteDataSourceProvider)),
);
final lifeServiceUseCasesProvider = Provider<LifeServiceUseCases>(
  (ref) => LifeServiceUseCases(ref.read(lifeServiceRepositoryProvider)),
);
