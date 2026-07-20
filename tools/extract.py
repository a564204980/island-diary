import os

path = r'd:\project\island_diary\lib\features\record\presentation\pages\diary_editor_page.dart'
mixin_path = r'd:\project\island_diary\lib\shared\widgets\diary_entry\mixins\diary_editor_sheets_mixin.dart'

with open(path, 'r', encoding='utf-8') as f:
    source = f.read()

def extract_method(source, name):
    idx = source.find(name)
    if idx == -1: return None, source
    
    start_idx = source.rfind('\n', 0, idx) + 1
    brace_idx = source.find('{', idx)
    if brace_idx == -1: return None, source
    
    brace_count = 0
    in_string = False
    string_char = ''
    in_line_comment = False
    in_block_comment = False
    
    end_idx = -1
    
    i = brace_idx
    while i < len(source):
        char = source[i]
        
        if in_line_comment:
            if char == '\n': in_line_comment = False
        elif in_block_comment:
            if char == '*' and i + 1 < len(source) and source[i+1] == '/':
                in_block_comment = False
                i += 1
        elif in_string:
            if char == '\\':
                i += 1
            elif char == string_char:
                in_string = False
        else:
            if char == '/' and i + 1 < len(source):
                if source[i+1] == '/':
                    in_line_comment = True
                    i += 1
                elif source[i+1] == '*':
                    in_block_comment = True
                    i += 1
            elif char in ["'", '"']:
                in_string = True
                string_char = char
            elif char == '{':
                brace_count += 1
            elif char == '}':
                brace_count -= 1
                if brace_count == 0:
                    end_idx = i + 1
                    break
        i += 1
        
    if end_idx != -1:
        method_code = source[start_idx:end_idx]
        new_source = source[:start_idx] + source[end_idx:]
        return method_code, new_source
    return None, source

methods = ['void _showBookSelector', 'void _showMoreBottomSheet', 'Widget _buildMoreMenuItem', 'void _showCustomMoodPicker', 'void _showAnnotationSheet']
extracted = []

for m in methods:
    code, source = extract_method(source, m)
    if code:
        extracted.append(code)

source = source.replace('DiaryEditorInsertMixin {', 'DiaryEditorInsertMixin, DiaryEditorSheetsMixin {')
import_stmt = "import 'package:island_diary/shared/widgets/diary_entry/mixins/diary_editor_sheets_mixin.dart';\n"
source = source.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\n" + import_stmt)

with open(path, 'w', encoding='utf-8', newline='\n') as f:
    f.write(source)

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
mixin_code += '\n\n'.join(extracted) + '\n}\n'

with open(mixin_path, 'w', encoding='utf-8', newline='\n') as f:
    f.write(mixin_code)

print('SUCCESS')
