import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';

import 'package:image/image.dart' as img;

class CropSample extends StatefulWidget {
  const CropSample({required this.image});

  static Route route({required File image}) {
    return MaterialPageRoute<void>(
      builder: (context) => CropSample(image: image),
    );
  }

  final File image;

  @override
  _CropSampleState createState() => _CropSampleState();
}

class _CropSampleState extends State<CropSample> {
  final _cropController = CropController();
  late final _imageData = widget.image.readAsBytesSync();

  var _isSumbnail = false;
  var _isCropping = false;
  var _isCircleUi = false;
  var _statusText = '';

  Uint8List? _croppedData;

  /// 画像の平均RGB値を算出する
  Color _calcAverageRgb(Uint8List data) {
    final image = img.decodeImage(data);
    final pixels = image!.getBytes();

    double r = 0, g = 0, b = 0;

    // pixelsにはr, g, b, aが含まれているため、aを飛ばしている
    for (int i = 0; i < pixels.length; i += 4) {
      r += pixels[i];
      g += pixels[i + 1];
      b += pixels[i + 2];
    }

    r /= (pixels.length / 4);
    g /= (pixels.length / 4);
    b /= (pixels.length / 4);

    // print('$r, $g, $b');

    final hex = 'FF' +
        r.toInt().toRadixString(16) +
        g.toInt().toRadixString(16) +
        b.toInt().toRadixString(16);

    // print(color);
    return Color(int.parse(hex, radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: Visibility(
          visible: !_isCropping,
          child: Column(
            children: [
              Expanded(
                child: Visibility(
                  visible: _croppedData == null,
                  child: Stack(
                    children: [
                      Crop(
                        controller: _cropController,
                        image: _imageData,
                        onCropped: (croppedData) {
                          setState(() {
                            _croppedData = croppedData;
                            _isCropping = false;
                            // 切り取られた画像の平均RGB値を算出する
                            _calcAverageRgb(croppedData);
                          });
                        },
                        withCircleUi: _isCircleUi,
                        onStatusChanged: (status) => setState(() {
                          _statusText = <CropStatus, String>{
                                CropStatus.nothing: 'Crop has no image data',
                                CropStatus.loading:
                                    'Crop is now loading given image',
                                CropStatus.ready: 'Crop is now ready!',
                                CropStatus.cropping:
                                    'Crop is now cropping image',
                              }[status] ??
                              '';
                        }),
                        initialSize: 0.5,
                        maskColor: _isSumbnail ? Colors.white : null,
                        cornerDotBuilder: (size, edgeAlignment) => _isSumbnail
                            ? const SizedBox.shrink()
                            : const DotControl(),
                      ),
                      Positioned(
                        right: 16,
                        bottom: 16,
                        child: GestureDetector(
                          onTapDown: (_) => setState(() => _isSumbnail = true),
                          onTapUp: (_) => setState(() => _isSumbnail = false),
                          child: CircleAvatar(
                            backgroundColor:
                                _isSumbnail ? Colors.blue.shade50 : Colors.blue,
                            child: const Center(
                              child: Icon(Icons.crop_free_rounded),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  replacement: Center(
                    child: _croppedData == null
                        ? const SizedBox.shrink()
                        : Column(
                            children: [
                              Container(
                                width: double.infinity,
                                height: 64.0,
                                decoration: BoxDecoration(
                                  color: _calcAverageRgb(_croppedData!),
                                ),
                                child: const Text('切り取り領域の平均カラー'),
                              ), //
                              const SizedBox(height: 16.0),
                              Image.memory(_croppedData!),
                            ],
                          ),
                  ),
                ),
              ),
              if (_croppedData == null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.crop_7_5),
                            onPressed: () {
                              _isCircleUi = false;
                              _cropController.aspectRatio = 16 / 4;
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.crop_16_9),
                            onPressed: () {
                              _isCircleUi = false;
                              _cropController.aspectRatio = 16 / 9;
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.crop_5_4),
                            onPressed: () {
                              _isCircleUi = false;
                              _cropController.aspectRatio = 4 / 3;
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.crop_square),
                            onPressed: () {
                              _isCircleUi = false;
                              _cropController
                                ..withCircleUi = false
                                ..aspectRatio = 1;
                            },
                          ),
                          IconButton(
                              icon: const Icon(Icons.circle),
                              onPressed: () {
                                _isCircleUi = true;
                                _cropController.withCircleUi = true;
                              }),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _isCropping = true;
                            });
                            _isCircleUi
                                ? _cropController.cropCircle()
                                : _cropController.crop();
                          },
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Text('CROP IT!'),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              Text(_statusText),
              const SizedBox(height: 16),
            ],
          ),
          replacement: const CircularProgressIndicator(),
        ),
      ),
    );
  }
}
