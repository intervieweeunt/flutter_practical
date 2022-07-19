import 'package:flutter_practical/domain/base/base_usecase.dart';
import 'package:flutter_practical/domain/files/repository/file_repository.dart';

import '../task/task.dart';

class LocalFileUseCase extends BaseUseCase<List<Task>> {
  final FileRepository fileRepository;

  LocalFileUseCase({required this.fileRepository});

  @override
  Future<List<Task>> perform() {
    return fileRepository.getDownloadedFiles();
  }
}
