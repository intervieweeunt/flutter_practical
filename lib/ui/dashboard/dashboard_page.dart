import 'dart:io';

import 'package:connectivity/connectivity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_practical/common/app_utils.dart';
import 'package:flutter_practical/ui/dashboard/dashboard_viewmodel.dart';
import 'package:mime/mime.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with WidgetsBindingObserver {
  final DashboardViewModel dashboardViewModel = DashboardViewModel();

  @override
  void initState() {
    super.initState();
    dashboardViewModel.checkPermission();

    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      if (result != ConnectivityResult.none) {
        dashboardViewModel.checkPermission();
      }
    });

    WidgetsBinding.instance.addObserver(this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Image sample"),
      ),
      body: StreamBuilder<List<DownloadTask>?>(
          stream: dashboardViewModel.onCurrentFilesChanged,
          builder: (context, AsyncSnapshot<List<DownloadTask>?> snapshot) {
            if (snapshot.hasData) {
              return Padding(
                padding: const EdgeInsets.only(top: 10, left: 10, right: 10),
                child: GridView.builder(
                  itemCount: snapshot.data?.length,
                  itemBuilder: (context, index) {
                    final DownloadTask item = snapshot.data![index];
                    return InkWell(
                      onTap: () {
                        //OpenFile.open(item.filename);
                        FlutterDownloader.open(taskId: item.taskId);
                      },
                      child: Container(
                        width: MediaQuery.of(context).size.width,
                        decoration: BoxDecoration(
                            color: Colors.greenAccent,
                            borderRadius: BorderRadius.circular(10)),
                        height: 100,
                        child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: _getFile(item.filename)),
                      ),
                    );
                  },
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 4.0,
                      mainAxisSpacing: 4.0),
                ),
              );
            } else if (snapshot.hasError) {
              return Center(child: Text(snapshot.error.toString()));
            } else {
              Container();
            }
            return const Center(child: CircularProgressIndicator());
          }),
    );
  }

  Widget _getFile(String? filename) {
    if (filename != null) {
      String? mimeStr = lookupMimeType(filename);
      var fileType = mimeStr?.split('/');
      if (fileType?.contains("image") == true) {
        return Image.file(
          File(localPath + "/" + filename),
          fit: BoxFit.cover,
        );
      } else {
        if (fileType == null) {
          return const Center(child: Text("Unknown File"));
        } else {
          return Center(child: Text("$fileType File"));
        }
      }
    } else {
      return const Center(child: Text("Not Available"));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    dashboardViewModel.closeObservable();
    super.dispose();
  }

  void getLocalFiles() {
    dashboardViewModel.getDownloadedList();
  }
}
