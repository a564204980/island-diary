path = r'd:\project\island_diary\lib\features\record\presentation\pages\diary_editor_page.dart'
mixin_path = r'd:\project\island_diary\lib\shared\widgets\diary_entry\mixins\diary_editor_sheets_mixin.dart'
kf_path = r'd:\project\island_diary\lib\features\record\presentation\widgets\editor\keyboard_follower.dart'
apb_path = r'd:\project\island_diary\lib\features\record\presentation\widgets\editor\animated_paper_background.dart'

with open(path, 'r', encoding='utf-8') as f:
    original_source = f.read()

source = original_source

# 1. Rename private methods to public in the entire source
source = source.replace('_showBookSelector', 'showBookSelector')
source = source.replace('_showCustomMoodPicker', 'showCustomMoodPicker')
source = source.replace('_showMoreBottomSheet', 'showMoreBottomSheet')
source = source.replace('_buildMoreMenuItem', 'buildMoreMenuItem')
source = source.replace('_showAnnotationSheet', 'showAnnotationSheet')
source = source.replace('_annotationColors', 'annotationColors')

# 2. Extract methods
def extract_method(source, start_str):
    idx = source.find(start_str)
    if idx == -1: return None, source
    start_idx = source.rfind('\n', 0, idx) + 1
    
    body_start_idx = source.find('{', source.find(')', idx))
    if body_start_idx == -1: return None, source
    
    brace_count = 0
    in_string = False
    string_char = ''
    in_line_comment = False
    in_block_comment = False
    
    end_idx = -1
    
    i = body_start_idx
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

methods = ['void showBookSelector', 'Future<void> showCustomMoodPicker', 'void showMoreBottomSheet', 'Widget buildMoreMenuItem', 'void showAnnotationSheet']
extracted_methods = []

for m in methods:
    code, source = extract_method(source, m)
    if code:
        extracted_methods.append(code)

# 3. Extract annotationColors list
idx = source.find('static const List<Map<String, String>> annotationColors')
if idx != -1:
    start_idx = source.rfind('\n', 0, idx) + 1
    end_idx = source.find(';', idx) + 1
    extracted_methods.insert(0, source[start_idx:end_idx])
    source = source[:start_idx] + source[end_idx:]

# 4. Extract KeyboardFollower (renamed to public)
source = source.replace('class _KeyboardFollower', 'class KeyboardFollower')
source = source.replace('State<_KeyboardFollower>', 'State<KeyboardFollower>')
source = source.replace('class _KeyboardFollowerState', 'class _KeyboardFollowerState')
source = source.replace('_KeyboardFollower(', 'KeyboardFollower(')

kf_code, source = extract_method(source, 'class KeyboardFollower extends StatefulWidget')
if kf_code:
    kf_state_code, source = extract_method(source, 'class _KeyboardFollowerState extends State<KeyboardFollower>')
    kf_full = '''import 'package:flutter/material.dart';
import 'dart:math';
''' + '\n' + kf_code + '\n' + (kf_state_code or '') + '\n'
    with open(kf_path, 'w', encoding='utf-8', newline='\n') as f:
        f.write(kf_full)

# 5. Extract AnimatedPaperBackground (renamed to public)
source = source.replace('class _AnimatedPaperBackground', 'class AnimatedPaperBackground')
source = source.replace('_AnimatedPaperBackground(', 'AnimatedPaperBackground(')

apb_code, source = extract_method(source, 'class AnimatedPaperBackground extends StatelessWidget')
if apb_code:
    apb_full = '''import 'package:flutter/material.dart';
import 'package:island_diary/features/record/presentation/widgets/editor/paper_background.dart';
''' + '\n' + apb_code + '\n'
    with open(apb_path, 'w', encoding='utf-8', newline='\n') as f:
        f.write(apb_full)

# 6. Finalize diary_editor_page.dart
source = source.replace('DiaryEditorInsertMixin<DiaryEditorPage> {', 'DiaryEditorInsertMixin<DiaryEditorPage>, DiaryEditorSheetsMixin {')

import_stmts = """import 'package:island_diary/shared/widgets/diary_entry/mixins/diary_editor_sheets_mixin.dart';
import 'package:island_diary/features/record/presentation/widgets/editor/keyboard_follower.dart';
import 'package:island_diary/features/record/presentation/widgets/editor/animated_paper_background.dart';
"""
source = source.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\n" + import_stmts)

with open(path, 'w', encoding='utf-8', newline='\n') as f:
    f.write(source)

# 7. Write Mixin
# Get all imports from original file
imports = []
for line in original_source.split('\n'):
    if line.startswith('import '):
        imports.append(line)

mixin_code = '\n'.join(imports) + '''

mixin DiaryEditorSheetsMixin on State<DiaryEditorPage>, DiaryEditorCoreMixin {
'''
mixin_code += '\n\n'.join(extracted_methods) + '\n}\n'

with open(mixin_path, 'w', encoding='utf-8', newline='\n') as f:
    f.write(mixin_code)

print('SUCCESS')
