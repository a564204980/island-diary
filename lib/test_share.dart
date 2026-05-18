import 'package:share_plus/share_plus.dart';

void main() async {
  await SharePlus.instance.share(ShareParams(uri: Uri.parse('https://example.com')));
  await SharePlus.instance.share(ShareParams(files: [XFile('')])); // Avoid empty list ArgumentError
}
