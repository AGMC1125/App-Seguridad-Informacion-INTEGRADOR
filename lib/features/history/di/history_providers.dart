import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/datasources/history_remote_datasource.dart';
import '../data/repositories/history_repository_impl.dart';
import '../domain/repositories/history_repository.dart';
import '../domain/usecases/get_history_usecase.dart';
import '../domain/usecases/save_history_usecase.dart';
import '../domain/usecases/delete_history_item_usecase.dart';

// ── Capa de datos ─────────────────────────────────────────────────────────────

final historyRemoteDataSourceProvider = Provider<HistoryRemoteDataSource>(
  (ref) => const HistoryRemoteDataSource(),
);

final historyRepositoryProvider = Provider<HistoryRepository>(
  (ref) => HistoryRepositoryImpl(ref.read(historyRemoteDataSourceProvider)),
);

// ── Casos de uso ──────────────────────────────────────────────────────────────

final getHistoryUseCaseProvider = Provider<GetHistoryUseCase>(
  (ref) => GetHistoryUseCase(ref.read(historyRepositoryProvider)),
);

final saveHistoryUseCaseProvider = Provider<SaveHistoryUseCase>(
  (ref) => SaveHistoryUseCase(ref.read(historyRepositoryProvider)),
);

final deleteHistoryItemUseCaseProvider = Provider<DeleteHistoryItemUseCase>(
  (ref) => DeleteHistoryItemUseCase(ref.read(historyRepositoryProvider)),
);
