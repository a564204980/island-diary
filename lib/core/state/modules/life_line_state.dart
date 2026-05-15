part of '../user_state.dart';

/// 人生线状态管理 Mixin
mixin LifeLineMixin {
  /// 所有已创建的人生线列表
  final ValueNotifier<List<LifeLineProfile>> lifeLines = ValueNotifier<List<LifeLineProfile>>([]);
  
  /// 当前激活的人生线 ID
  final ValueNotifier<String> currentLifeLineId = ValueNotifier<String>('default');

  /// 初始化人生线数据
  void loadLifeLines(SharedPreferences prefs) {
    // 1. 加载当前选中的 ID
    currentLifeLineId.value = prefs.getString('current_life_line_id') ?? 'default';

    // 2. 加载人生线列表
    final String? listJson = prefs.getString('life_line_list');
    if (listJson != null) {
      try {
        final List<dynamic> decoded = json.decode(listJson);
        lifeLines.value = decoded.map((m) => LifeLineProfile.fromMap(m)).toList();
      } catch (e) {
        debugPrint('加载人生线列表失败: $e');
      }
    }
    
    // 强制迁移检查：即使列表不为空，只要还没迁移过且存在旧数据，就执行迁移
    final bool alreadyMigrated = prefs.getBool('has_migrated_to_life_line') ?? false;
    if (!alreadyMigrated && prefs.containsKey('user_name')) {
      _migrateOldData(prefs);
      prefs.setBool('has_migrated_to_life_line', true);
      
      // 迁移期间，强制将 default 档案的名字设为旧昵称，以明确这是老账号
      if (lifeLines.value.isNotEmpty) {
        final defaultIdx = lifeLines.value.indexWhere((p) => p.id == 'default');
        if (defaultIdx != -1) {
          final oldName = prefs.getString('user_name');
          if (oldName != null) {
            lifeLines.value[defaultIdx] = lifeLines.value[defaultIdx].copyWith(
              name: oldName,
              bio: prefs.getString('user_bio'),
              avatarPath: prefs.getString('custom_avatar_path'),
            );
            _saveLifeLineList(prefs);
          }
        }
      }
    }

    // 3. 如果列表为空，创建一个默认的人生线
    if (lifeLines.value.isEmpty) {
      final defaultProfile = LifeLineProfile(
        id: 'default',
        name: prefs.getString('user_name') ?? '海岛新居民',
        bio: prefs.getString('user_bio') ?? '',
        avatarPath: prefs.getString('custom_avatar_path'),
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );
      lifeLines.value = [defaultProfile];
      _saveLifeLineList(prefs);
    }
  }

  /// 迁移旧版本的数据到 default 命名空间
  void _migrateOldData(SharedPreferences prefs) {
    final allKeys = prefs.getKeys();
    bool migrated = false;
    for (final key in allKeys) {
      // 跳过已经是命名空间的键和系统键
      if (key.startsWith('life_line_')) continue;
      if (key == 'current_life_line_id') continue;
      
      final val = prefs.get(key);
      if (val == null) continue;
      
      final newKey = 'life_line_default_$key';
      // 如果新键已存在，不覆盖（理论上不应该存在）
      if (prefs.containsKey(newKey)) continue;

      if (val is String) {
        prefs.setString(newKey, val);
      } else if (val is bool) {
        prefs.setBool(newKey, val);
      } else if (val is int) {
        prefs.setInt(newKey, val);
      } else if (val is double) {
        prefs.setDouble(newKey, val);
      } else if (val is List<String>) {
        prefs.setStringList(newKey, val);
      }
      migrated = true;
    }
    if (migrated) {
      debugPrint('已完成旧数据迁移至 default 命名空间');
    }
  }

  /// 获取带命名空间的存储键名
  /// 规则: life_line_{currentId}_{originalKey}
  /// 如果是全局 Key (如人生线列表本身)，则不加前缀
  String n(String key) {
    if (key == 'life_line_list' || key == 'current_life_line_id') return key;
    return 'life_line_${currentLifeLineId.value}_$key';
  }

  /// 创建新的人生线
  Future<void> createLifeLine(String name) async {
    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    final newProfile = LifeLineProfile(
      id: newId,
      name: name,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    
    lifeLines.value = [...lifeLines.value, newProfile];
    final prefs = await SharedPreferences.getInstance();
    await _saveLifeLineList(prefs);
  }

  /// 删除人生线
  Future<void> deleteLifeLine(String id) async {
    if (id == 'default' && lifeLines.value.length == 1) return; // 不能删除最后一个
    
    lifeLines.value = lifeLines.value.where((p) => p.id != id).toList();
    final prefs = await SharedPreferences.getInstance();
    await _saveLifeLineList(prefs);
    
    // 如果删除的是当前的，自动切换回默认
    if (currentLifeLineId.value == id) {
      await switchLifeLine(lifeLines.value.first.id);
    }
  }

  /// 切换人生线
  Future<void> switchLifeLine(String id) async {
    if (currentLifeLineId.value == id) return;
    
    currentLifeLineId.value = id;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_life_line_id', id);
    
    // 重新触发全局数据加载，以加载新角色的数据
    await UserState().loadFromStorage();
  }

  /// 保存人生线列表到本地
  Future<void> _saveLifeLineList(SharedPreferences prefs) async {
    final String jsonStr = json.encode(lifeLines.value.map((p) => p.toMap()).toList());
    await prefs.setString('life_line_list', jsonStr);
  }

  /// 更新当前角色的个人资料 (同步到列表和具体的持久化字段)
  Future<void> updateCurrentProfile({String? name, String? bio, String? avatarPath}) async {
    final index = lifeLines.value.indexWhere((p) => p.id == currentLifeLineId.value);
    if (index != -1) {
      final updated = lifeLines.value[index].copyWith(
        name: name,
        bio: bio,
        avatarPath: avatarPath,
      );
      lifeLines.value[index] = updated;
      lifeLines.value = List.from(lifeLines.value); // 触发通知
      
      final prefs = await SharedPreferences.getInstance();
      await _saveLifeLineList(prefs);
    }
  }
}
