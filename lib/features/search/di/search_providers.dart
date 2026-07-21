import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/datasources/search_remote_datasource.dart';
import '../data/repositories/search_repository_impl.dart';
import '../domain/repositories/search_repository.dart';
import '../domain/usecases/search_signs_usecase.dart';
// ── Capa de datos ─────────────────────────────────────────────────────────────

final searchRemoteDataSourceProvider = Provider<SearchRemoteDataSource>(
  (ref) => const SearchRemoteDataSource(),
);

final searchRepositoryProvider = Provider<SearchRepository>(
  (ref) => SearchRepositoryImpl(ref.read(searchRemoteDataSourceProvider)),
);

// ── Casos de uso ──────────────────────────────────────────────────────────────

final searchSignsUseCaseProvider = Provider<SearchSignsUseCase>(
  (ref) => SearchSignsUseCase(ref.read(searchRepositoryProvider)),
);

