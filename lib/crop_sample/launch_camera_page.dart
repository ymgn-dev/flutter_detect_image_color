import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_detect_image_color/crop_sample/crop_sample.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:image_picker/image_picker.dart';

enum StartupState { busy, success, error, noData }

class LaunchCameraPage extends HookWidget {
  LaunchCameraPage({Key? key}) : super(key: key);

  static Route route() {
    return MaterialPageRoute<void>(
      builder: (context) => LaunchCameraPage(),
    );
  }

  final _startupStatus = StreamController<StartupState>();

  File? _image;
  final _imagePicker = ImagePicker();

  Future<void> _getImageFromCamera() async {
    _startupStatus.add(StartupState.busy);

    try {
      final pickedFile =
          await _imagePicker.pickImage(source: ImageSource.camera);

      if (pickedFile == null) {
        _startupStatus.add(StartupState.error);
        return;
      }

      _image = File(pickedFile.path);
      _startupStatus.add(StartupState.success);
    } on PlatformException catch (e) {
      _startupStatus.add(StartupState.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    useEffect(() {
      WidgetsBinding.instance!.addPostFrameCallback((_) {
        _startupStatus.add(StartupState.noData);
      });
    }, const []);

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: StreamBuilder<StartupState>(
          stream: _startupStatus.stream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting ||
                snapshot.hasError) {
              print('waiting or hasError');
              return const Center(child: CircularProgressIndicator.adaptive());
            }

            final startupState = snapshot.data!;

            switch (startupState) {
              case StartupState.error:
              case StartupState.noData:
                print('startupState.error or noData');
                _getImageFromCamera();
                return const Center(
                  child: CircularProgressIndicator.adaptive(),
                );
              case StartupState.busy:
                print('startupState.busy');
                return const Center(
                  child: CircularProgressIndicator.adaptive(),
                );
              case StartupState.success:
                print('startupState.success');
                return CropSample(image: _image!);
              // return _PickedImage(image: _image!);
            }
          },
        ),
      ),
    );
  }
}

class _PickedImage extends HookWidget {
  const _PickedImage({required this.image});

  final File image;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Image.file(image),
    );
  }
}
