import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:island_diary/features/profile/presentation/widgets/decoration/form_selection_sheet.dart';

void main() {
  test('mascot form assets exist on disk', () {
    // The form sheet renders these paths directly, so a missing file becomes
    // a runtime image-load error when the user opens mascot customization.
    final missingAssets = MascotFormSelectionSheet.mascotForms
        .map((form) => form['path'])
        .whereType<String>()
        .where((path) => !File(path).existsSync())
        .toList();

    expect(missingAssets, isEmpty);
  });
}
