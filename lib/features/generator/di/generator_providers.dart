import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/datasources/generator_remote_datasource.dart';
import '../data/repositories/generator_repository_impl.dart';
import '../domain/repositories/generator_repository.dart';
import '../domain/usecases/generate_merged_video_usecase.dart';
// ── Capa de datos ─────────────────────────────────────────────────────────────

final generatorRemoteDataSourceProvider = Provider<GeneratorRemoteDataSource>(
  (ref) => const GeneratorRemoteDataSource(),
);

final generatorRepositoryProvider = Provider<GeneratorRepository>(
  (ref) => GeneratorRepositoryImpl(ref.read(generatorRemoteDataSourceProvider)),
);

// ── Casos de uso ──────────────────────────────────────────────────────────────

final generateMergedVideoUseCaseProvider = Provider<GenerateMergedVideoUseCase>(
  (ref) => GenerateMergedVideoUseCase(ref.read(generatorRepositoryProvider)),
);

