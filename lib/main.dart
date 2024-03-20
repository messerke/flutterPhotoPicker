import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Photo Timer App',
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<AssetEntity> recentPhotos = [];
  DateTime? timerStart;

  @override
  void initState() {
    super.initState();
    requestPermissions();
    startTimer();
  }

  Future<bool> requestPermissions() async {
    final permission = await Permission.mediaLibrary.status;

    // If permission is not granted, request it
    if (!permission.isGranted) {
      final status = await Permission.photos.request();
      if (status.isGranted) {
        print("Permission granted");
        return status.isGranted;
      } else {
        print("Permission denied");
        return status.isDenied;
      }
    }
    return true;
  }

  void startTimer() async {
    bool hasPermission = await requestPermissions();
    if (!hasPermission) {
      print('Permission not granted');
      return;
    }

    print('Timer started');
    const duration = Duration(seconds: 10); // Set your desired timeout
    timerStart = DateTime.now();
    Timer(duration, () {
      print('Timer completed');
      showRecentPhotos();
    });
  }

  Future<void> showRecentPhotos() async {
    print('Showing recent photos');
    final hasPermission = await requestPermissions();
    if (!hasPermission) {
      print('Permission not granted');
      return;
    }

    final albums = await PhotoManager.getAssetPathList(onlyAll: true);
    if (albums.isEmpty) {
      print('No albums found or access denied.');
      return;
    }

    final recentAssets = await albums.first.getAssetListRange(
      start: 0,
      end: 100, // Adjust based on how many photos you want to fetch
    );

    if (recentAssets.isEmpty) {
      print('No recent photos found.');
      return;
    }

    setState(() {
      recentPhotos = recentAssets
          .where((asset) => asset.createDateTime.isAfter(timerStart!))
          .toList();
    });

    if (recentPhotos.isEmpty) {
      print('No photos taken after the app started.');
      return;
    }

    print('Photos found: ${recentPhotos.length}');
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
          ),
          itemCount: recentPhotos.length,
          itemBuilder: (context, index) {
            return FutureBuilder<Uint8List?>(
              future: recentPhotos[index].thumbnailData,
              builder:
                  (BuildContext context, AsyncSnapshot<Uint8List?> snapshot) {
                if (snapshot.connectionState == ConnectionState.done &&
                    snapshot.data != null) {
                  return Image.memory(snapshot.data!);
                }
                return const Center(child: CircularProgressIndicator());
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Photo Timer App'),
        ),
        body: const Center(
          child: Text('Waiting for timer to expire to show recent photos...'),
        ),
      ),
    );
  }
}
