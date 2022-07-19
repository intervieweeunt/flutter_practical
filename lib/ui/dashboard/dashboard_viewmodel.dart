import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_practical/data/files/hive/task_local_datasource_hive.dart';
import 'package:flutter_practical/data/files/repository/file_repository_impl.dart';
import 'package:flutter_practical/domain/files/usecase/download_file_usecase.dart';
import 'package:flutter_practical/domain/files/usecase/local_file_usecase.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rxdart/rxdart.dart';

class DashboardViewModel {
  static const _tag = "DashboardViewModel";

  var downloadFilesSubject = PublishSubject<List<void>>();

  /*StreamController<List<FileSystemEntity>> streamController =
      StreamController<List<FileSystemEntity>>();

  Stream<List<FileSystemEntity>> get onCurrentFilesChanged =>
      streamController.stream;*/

  List<DownloadTask> downloadedTasks = List.empty(growable: true);
  StreamController<List<DownloadTask>> streamController =
      StreamController<List<DownloadTask>>();

  Stream<List<DownloadTask>> get onCurrentFilesChanged =>
      streamController.stream;

  Stream<List<void>> get downloadFilesStream => downloadFilesSubject.stream;

  DownloadFileUseCase downloadFileUseCase = DownloadFileUseCase(
      fileRepository: FileRepositoryImpl(
          taskModelLocalDatasource: TaskModelLocalDatasourceHiveImpl()));

  LocalFileUseCase localFileUseCase = LocalFileUseCase(
      fileRepository: FileRepositoryImpl(
          taskModelLocalDatasource: TaskModelLocalDatasourceHiveImpl()));

  void getFilesList() async {
    try {
      downloadFilesSubject = PublishSubject<List<void>>();
      downloadFilesSubject.sink.add(await downloadFileUseCase.perform());
      _downloadListener();
    } catch (e) {
      downloadFilesSubject.sink.addError(e);
    }
  }

  void getDownloadedList() async {
    try {
      //var list = await getLocalDownloadedFile();
      var downloadedFiles = await FlutterDownloader.loadTasks();
      streamController.sink.add(downloadedFiles!);
    } catch (e) {
      print("$_tag, getDownloadedList $e");
    }
  }

  void _downloadListener() {
    ReceivePort _port = ReceivePort();
    IsolateNameServer.registerPortWithName(
        _port.sendPort, 'downloader_send_port');
    _port.listen((dynamic data) async {
      String id = data[0];
      DownloadTaskStatus status = data[1];
      int progress = data[2];
      if (status.toString() == "DownloadTaskStatus(3)" &&
          progress == 100 &&
          id != null) {
        String query = "SELECT * FROM task WHERE task_id='" + id + "'";
        var tasks = await FlutterDownloader.loadTasksWithRawQuery(query: query);
        if (tasks != null) {
          downloadedTasks.addAll(tasks.toList());
          streamController.sink.add(downloadedTasks);
        }
      }
    });
    FlutterDownloader.registerCallback(_downloadCallback);
  }

  void _downloadCallback(String id, DownloadTaskStatus status, int progress) {
    print('$_tag, _downloadCallback >> Isolate Callback: task ($id) is in status ($status) and process ($progress)');
    final SendPort send =
        IsolateNameServer.lookupPortByName('downloader_send_port')!;
    send.send([id, status, progress]);
  }

  /* void getDownloadedList() async {
    try {
       FlutterDownloader.registerCallback((id, status, progress) async {
        if (status == DownloadTaskStatus.complete) {
          var completedTask = await FlutterDownloader.loadTasksWithRawQuery(
              query: "SELECT * FROM task WHERE task_id='$id");
          print("$_tag, completedTask >> ${completedTask}");
          if(completedTask!=null) {
            downloadedTasks.addAll(completedTask.toList());
          }
        }
        streamController.sink.add(downloadedTasks);
      });
    } catch (e) {
      streamController.sink.addError(e);
      print("$_tag, $e");
    }
  }*/

  void closeObservable() {
    downloadFilesSubject.close();
  }

  Future<bool> checkPermission() async {
    bool permissionStatus = false;
    var status = await Permission.storage.status;
    if (Platform.isIOS) {
      if (status.isGranted) {
        permissionStatus = true;
        await Permission.storage.request();
        getFilesList();
      } else if (status.isDenied) {
        await Permission.storage.request();
        permissionStatus = false;
      } else {
        openAppSettings();
      }
    } else {
      if (status.isDenied) {
        final tempStatus = await Permission.storage.request();
        if (tempStatus.isGranted) {
          getFilesList();
          return true;
        }
      } else if (status.isPermanentlyDenied) {
        openAppSettings();
      } else if (status.isGranted) {
        permissionStatus = true;
        getFilesList();
        return permissionStatus;
      } else {
        openAppSettings();
      }
    }
    return permissionStatus;
  }
}
