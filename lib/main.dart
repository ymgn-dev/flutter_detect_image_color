import 'package:flutter/material.dart';
import 'package:flutter_detect_image_color/crop_sample/crop_sample.dart';
import 'package:flutter_detect_image_color/crop_sample/launch_camera_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const SelectAlgorithmPage(),
    );
  }
}

class SelectAlgorithmPage extends StatelessWidget {
  const SelectAlgorithmPage({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('画像から色を判別するサンプル'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.crop_16_9),
              title: const Text('画像切り取り'),
              onTap: () {
                Navigator.of(context).push<void>(LaunchCameraPage.route());
              },
            ),
          ],
        ),
      ),
    );
  }
}
