import os

page_path = 'lib/features/profile/presentation/pages/diary_book_export_page.dart'
with open(page_path, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. 注入 updateState
if 'Widget? _canvasSubtreeCache;' not in content:
    old_state = 'class _DiaryBookExportPageState extends State<DiaryBookExportPage> with TickerProviderStateMixin {\n'
    new_state = old_state + '''  Widget? _canvasSubtreeCache;

  void updateState(VoidCallback fn, {bool rebuildCanvas = true}) {
    if (rebuildCanvas) {
      _canvasSubtreeCache = null;
    }
    mounted ? setState(fn) : fn();
  }
'''
    content = content.replace(old_state, new_state)

# 2. 替换 setState 为 updateState (只替换类体里的, setState() 前面通常是空格)
content = content.replace(' setState(', ' updateState(')

# 3. 提取 _getCanvasSubtree
if 'Widget _getCanvasSubtree()' not in content:
    start_str = '              // 1. 画布及浮动手势工具区域\n              Positioned.fill('
    end_str = '              // 2. 浮动悬浮工具栏 (定位在配置面板上方)'
    
    # 找到这两个字符串之间的代码
    start_idx = content.find(start_str)
    end_idx = content.find(end_str)
    
    if start_idx != -1 and end_idx != -1:
        canvas_block = content[start_idx + len('              // 1. 画布及浮动手势工具区域\n'):end_idx]
        
        # 将 canvas_block 抽取出为函数
        new_func = '''
  Widget _getCanvasSubtree() {
    if (_canvasSubtreeCache != null) return _canvasSubtreeCache!;
    _canvasSubtreeCache = ''' + canvas_block.strip()[:-1] + '''; // 替换逗号为分号
    return _canvasSubtreeCache!;
  }
'''
        # 插入到 build 之前
        build_str = '  @override\n  Widget build(BuildContext context) {'
        content = content.replace(build_str, new_func + '\n' + build_str)
        
        # 替换原有的 block 为调用
        replacement = '              // 1. 画布及浮动手势工具区域\n              _getCanvasSubtree(),\n              // 2. 浮动悬浮工具栏 (定位在配置面板上方)'
        content = content[:start_idx] + replacement + content[end_idx + len(end_str):]

with open(page_path, 'w', encoding='utf-8') as f:
    f.write(content)
