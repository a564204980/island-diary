import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final imageFile = File('assets/launch_screen_title.png');
  final original = img.decodeImage(imageFile.readAsBytesSync())!;
  
  // Create a canvas that is a square, 2.0 times the width of the original image
  // This ensures the actual text fits inside the inner circle safe zone (which is about 66% of the icon diameter)
  final size = (original.width * 2.0).toInt();
  
  final padded = img.Image(width: size, height: size, numChannels: 4);
  img.fill(padded, color: img.ColorRgba8(210, 226, 249, 255));
  
  // Draw the original image in the center
  final x = (size - original.width) ~/ 2;
  final y = (size - original.height) ~/ 2;
  img.compositeImage(padded, original, dstX: x, dstY: y);
  
  File('assets/launch_screen_title_padded.png').writeAsBytesSync(img.encodePng(padded));
  stdout.writeln('Padded image generated successfully.');
}
