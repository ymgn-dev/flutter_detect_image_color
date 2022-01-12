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

  // 各カラーである確率
  double probRed = 0.0;
  double probYellow = 0.0;
  double probGreen = 0.0;
  double probBlue = 0.0;
  double probPurple = 0.0;

  /// 画像の平均RGB値を算出する
  Future<Color> _calcAverageRgb(Uint8List data) async {
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

    // 色同士の距離を算出する関数
    // 3次元の距離
    double _calcColorDist(Color lhs, Color rhs) {
      return ((lhs.red - rhs.red) *
              (lhs.green * rhs.green) *
              (lhs.blue * rhs.blue) /
              100000)
          .abs();
    }

    // 数値の逆数を算出する関数
    double reciprocal(double d) => 1 / d;

    final averageColor = Color(int.parse(hex, radix: 16));
    const red = Colors.red;
    const yellow = Colors.yellow;
    const green = Colors.green;
    const blue = Colors.blue;
    const purple = Colors.purple;

    final dRed = _calcColorDist(averageColor, red);
    final dYellow = _calcColorDist(averageColor, yellow);
    final dGreen = _calcColorDist(averageColor, green);
    final dBlue = _calcColorDist(averageColor, blue);
    final dPurple = _calcColorDist(averageColor, purple);

    final rRed = reciprocal(dRed);
    final rYellow = reciprocal(dYellow);
    final rGreen = reciprocal(dGreen);
    final rBlue = reciprocal(dGreen);
    final rPurple = reciprocal(dPurple);

    final sum = rRed + rYellow + rGreen + rBlue + rPurple;

    probRed = rRed / sum * 100;
    probYellow = rYellow / sum * 100;
    probGreen = rGreen / sum * 100;
    probBlue = rBlue / sum * 100;
    probPurple = rPurple / sum * 100;

    print('カラー: (r: $r, g: $g, b: $b)');
    print('赤の確率: $probRed');
    print('黄の確率: $probYellow');
    print('緑の確率: $probGreen');
    print('青の確率: $probBlue');
    print('紫の確率: $probPurple');

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
                        : FutureBuilder(
                            future: _calcAverageRgb(_croppedData!),
                            builder: (context, AsyncSnapshot<Color> snapshot) {
                              if (snapshot.connectionState ==
                                      ConnectionState.waiting ||
                                  snapshot.hasError) {
                                return const Center(
                                  child: CircularProgressIndicator.adaptive(),
                                );
                              }

                              final color = snapshot.data!;

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('切り取り領域の平均カラー'),
                                  Container(
                                    width: double.infinity,
                                    height: 64.0,
                                    decoration: BoxDecoration(
                                      color: color,
                                    ),
                                    child: Text(
                                      '(R, G, B): ${color.red}, ${color.green}, ${color.blue}',
                                    ),
                                  ), //
                                  const SizedBox(height: 16.0),
                                  const Text('↓カラーごとの推定値'),
                                  Container(
                                    width: MediaQuery.of(context).size.width *
                                        probRed /
                                        100,
                                    height: 32.0,
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                    ),
                                  ),
                                  const SizedBox(height: 4.0),
                                  Container(
                                    width: MediaQuery.of(context).size.width *
                                        probYellow /
                                        100,
                                    height: 32.0,
                                    decoration: const BoxDecoration(
                                      color: Colors.yellow,
                                    ),
                                  ),
                                  const SizedBox(height: 4.0),
                                  Container(
                                    width: MediaQuery.of(context).size.width *
                                        probGreen /
                                        100,
                                    height: 32.0,
                                    decoration: const BoxDecoration(
                                      color: Colors.green,
                                    ),
                                  ),
                                  const SizedBox(height: 4.0),
                                  Container(
                                    width: MediaQuery.of(context).size.width *
                                        probBlue /
                                        100,
                                    height: 32.0,
                                    decoration: const BoxDecoration(
                                      color: Colors.blue,
                                    ),
                                  ),
                                  const SizedBox(height: 4.0),
                                  Container(
                                    width: MediaQuery.of(context).size.width *
                                        probPurple /
                                        100,
                                    height: 32.0,
                                    decoration: const BoxDecoration(
                                      color: Colors.purple,
                                    ),
                                  ),
                                  const SizedBox(height: 4.0),
                                  Expanded(child: Image.memory(_croppedData!)),
                                ],
                              );
                            }),
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
