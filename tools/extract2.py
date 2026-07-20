path = r'd:\project\island_diary\lib\features\record\presentation\pages\diary_editor_page.dart'
mixin_path = r'd:\project\island_diary\lib\shared\widgets\diary_entry\mixins\diary_editor_sheets_mixin.dart'

with open(path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

extracted = lines[438:1325]
remaining = lines[:438] + lines[1325:]

# also add the import to remaining
import_stmt = "import 'package:island_diary/shared/widgets/diary_entry/mixins/diary_editor_sheets_mixin.dart';\n"
last_import = 0
for i, line in enumerate(remaining):
    if line.startswith('import '):
        last_import = i
remaining.insert(last_import + 1, import_stmt)

# also add mixin to `class _DiaryEditorPageState ... with ...`
for i, line in enumerate(remaining):
    if 'DiaryEditorInsertMixin {' in line:
        remaining[i] = line.replace('DiaryEditorInsertMixin {', 'DiaryEditorInsertMixin, DiaryEditorSheetsMixin {')
        break

# remove the bottom classes that I extracted previously
# which are from line 1335 downwards in the original file
for i, line in enumerate(remaining):
    if 'class _KeyboardFollower' in line:
        # truncate from i to end
        remaining = remaining[:i]
        remaining.append('}\n')
        break
        
# and rename _AnimatedPaperBackground if it's there
for i, line in enumerate(remaining):
    if '_AnimatedPaperBackground' in line:
        remaining[i] = line.replace('_AnimatedPaperBackground', 'AnimatedPaperBackground')

# add bottom class imports
last_import = 0
for i, line in enumerate(remaining):
    if line.startswith('import '):
        last_import = i
remaining.insert(last_import + 1, "import 'package:island_diary/features/record/presentation/widgets/editor/keyboard_sync_layout.dart';\n")
remaining.insert(last_import + 2, "import 'package:island_diary/features/record/presentation/widgets/editor/animated_paper_background.dart';\n")


with open(path, 'w', encoding='utf-8', newline='\n') as f:
    f.writelines(remaining)

mixin_code = '''import 'package:flutter/material.dart';
import 'package:island_diary/core/global/user_state.dart';
import 'package:island_diary/core/models/diary_book.dart';
import 'package:island_diary/utils/diary_utils.dart';
import 'package:island_diary/shared/widgets/diary_entry/mixins/diary_editor_core_mixin.dart';
import 'package:island_diary/features/record/presentation/pages/diary_editor_page.dart';
import 'package:island_diary/shared/widgets/diary_bottom_sheet.dart';
import 'package:island_diary/shared/widgets/custom_mood_picker.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';

mixin DiaryEditorSheetsMixin on State<DiaryEditorPage>, DiaryEditorCoreMixin {
'''
mixin_code += ''.join(extracted) + '}\n'

with open(mixin_path, 'w', encoding='utf-8', newline='\n') as f:
    f.write(mixin_code)

print('SUCCESS')
