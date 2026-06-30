// ignore_for_file: avoid_print
import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final file = File('assets/app_icon.png');
  final image = img.decodeImage(file.readAsBytesSync());
  if (image != null) {
    final pixel = image.getPixel(0, 0);
    // Convert a rgba pixel to hex code #RRGGBB
    final r = pixel.r.toInt().toRadixString(16).padLeft(2, '0');
    final g = pixel.g.toInt().toRadixString(16).padLeft(2, '0');
    final b = pixel.b.toInt().toRadixString(16).padLeft(2, '0');
    print('#$r$g$b');
  }
}
