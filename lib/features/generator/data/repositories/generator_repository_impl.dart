import '../../domain/entities/merged_video_result.dart';
import '../../domain/repositories/generator_repository.dart';
import '../datasources/generator_remote_datasource.dart';

class GeneratorRepositoryImpl implements GeneratorRepository {
  final GeneratorRemoteDataSource _dataSource;
  const GeneratorRepositoryImpl(this._dataSource);

  @override
  Future<MergedVideoResult> generateMerged({
    required String text,
    required String avatarCode,
    required String token,
  }) async {
    final model = await _dataSource.generateMerged(
      text: text,
      avatarCode: avatarCode,
      token: token,
    );
    return model.toEntity();
  }
}
