// ignore_for_file: avoid_print
import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final muralBytes = File('assets/images/jiangnan_mural.png').readAsBytesSync();
  var muralImg = img.decodeImage(muralBytes)!;
  if (muralImg.numChannels != 4) {
    print('Channels: ${muralImg.numChannels}');
    var newImg = img.Image(width: muralImg.width, height: muralImg.height, numChannels: 4);
    for (var p in muralImg) {
      newImg.setPixelRgba(p.x, p.y, p.r, p.g, p.b, 255);
    }
    print('New channels: ${newImg.numChannels}');
  }
}
