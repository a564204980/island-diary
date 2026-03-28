import 'dart:io';
import 'dart:typed_data';

void main() {
  final file = File('assets/images/decoration/furniture/bed2.png');
  if (!file.existsSync()) {
    print('File not found at ${file.absolute.path}');
    return;
  }
  final bytes = file.readAsBytesSync();
  if (bytes.length < 24) {
    print('File too small');
    return;
  }
  final data = ByteData.sublistView(bytes);
  final width = data.getUint32(16);
  final height = data.getUint32(20);
  print('Width: $width');
  print('Height: $height');
}
