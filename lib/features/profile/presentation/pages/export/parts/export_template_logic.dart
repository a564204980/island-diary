part of '../../diary_book_export_page.dart';

extension _ExportTemplateLogic on _DiaryBookExportPageState {
  Future<bool> _saveCurrentTemplate(String name) async {
    try {
      final template = ExportTemplateModel(
        name: name,
        pageSize: _pageSize,
        margin: _margin,
        pageBgSettings: _pageBgSettings,
        elements: _elements,
        createdAt: DateTime.now().toIso8601String(),
      );

      final dir = await _templatesDir;
      final file = File('${dir.path}/$name.json');
      
      final jsonStr = json.encode(template.toMap());
      await file.writeAsString(jsonStr);
      
      await _loadLocalTemplates();
      return true;
    } catch (e) {
      debugPrint('保存模板失败: $e');
      return false;
    }
  }

  // 删除某个本地模板文件
  Future<void> _deleteTemplate(ExportTemplateModel template) async {
    try {
      final dir = await _templatesDir;
      final file = File('${dir.path}/${template.name}.json');
      if (await file.exists()) {
        await file.delete();
      }
      await _loadLocalTemplates();
    } catch (e) {
      debugPrint('删除模板失败: $e');
    }
  }


  void _applyTemplate(ExportTemplateModel template) {
    _saveToHistory();
    updateState(() {
      _pageSize = template.pageSize;
      _margin.left = template.margin.left;
      _margin.right = template.margin.right;
      _margin.top = template.margin.top;
      _margin.bottom = template.margin.bottom;
      
      _pageBgSettings.clear();
      template.pageBgSettings.forEach((k, v) {
        _pageBgSettings[k] = v.copy();
      });

      _elements = template.elements.map((e) => e.copy()).toList();
      _selectedElementId = null;
      _editingElementId = null;
      
      _undoStack.clear();
      _redoStack.clear();
      
      _focusedPageIndex = 0;
    });

    _isZoomScaleInitialized = false;
    _recenterCanvas();

    showTopToast(
      context,
      '已套用模板 "${template.name}"',
      icon: Icons.check_circle_outline_rounded,
      iconColor: const Color(0xFF5A3E28),
    );
  }

  Future<void> _handleSaveTemplate({bool exitAfterSave = false}) async {
    final controller = TextEditingController(text: _exportSettings.fileName.isNotEmpty ? _exportSettings.fileName : '我的自定义模板');
    
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            width: 310,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.black.withValues(alpha: 0.05),
                width: 0.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 标题
                const Padding(
                  padding: EdgeInsets.only(top: 24, left: 24, right: 24),
                  child: Text(
                    '保存为模板',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'LXGWWenKai',
                      color: Color(0xFF2C2C2C),
                    ),
                  ),
                ),
                
                // 输入框
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F7F7),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.black.withValues(alpha: 0.05),
                        width: 0.5,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: TextField(
                      controller: controller,
                      autofocus: true,
                      style: const TextStyle(
                        fontSize: 14,
                        fontFamily: 'LXGWWenKai',
                        color: Color(0xFF2C2C2C),
                      ),
                      decoration: const InputDecoration(
                        hintText: '请输入模板名称...',
                        hintStyle: TextStyle(
                          fontSize: 14,
                          fontFamily: 'LXGWWenKai',
                          color: Colors.black38,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),

                // 分割线
                Container(
                  height: 0.5,
                  color: Colors.black.withValues(alpha: 0.05),
                ),

                // 操作按钮
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          Navigator.pop(dialogContext);
                          if (exitAfterSave) {
                            Navigator.pop(context);
                          }
                        },
                        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(20)),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 15),
                          child: Text(
                            "取消",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'LXGWWenKai',
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF8E8E93),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: 0.5,
                      height: 48,
                      color: Colors.black.withValues(alpha: 0.05),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final name = controller.text.trim();
                          if (name.isEmpty) return;
                          Navigator.pop(dialogContext); // 关掉输入弹窗
                          final success = await _saveCurrentTemplate(name);
                          if (!mounted) return;
                          if (success) {
                            showTopToast(
                              context,
                              '模板 "$name" 保存成功！',
                              icon: Icons.check_circle_rounded,
                              iconColor: const Color(0xFF10B981),
                            );
                            if (exitAfterSave) {
                              Navigator.pop(context); // 退出编辑器页面
                            }
                          } else {
                            showTopToast(
                              context,
                              '模板保存失败，请重试',
                              icon: Icons.error_outline_rounded,
                              iconColor: Colors.red,
                            );
                          }
                        },
                        borderRadius: const BorderRadius.only(bottomRight: Radius.circular(20)),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 15),
                          child: Text(
                            "确定",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'LXGWWenKai',
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFA68565),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }


  void _saveTemplateAndExit() {
    _handleSaveTemplate(exitAfterSave: true);
  }


}
