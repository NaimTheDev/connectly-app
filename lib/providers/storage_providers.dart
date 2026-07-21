import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../services/storage_service.dart';

part 'storage_providers.g.dart';

@Riverpod(keepAlive: true)
StorageService storageService(Ref ref) => StorageService();
