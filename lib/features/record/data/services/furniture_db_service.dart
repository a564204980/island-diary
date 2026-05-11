import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../../domain/models/furniture_item.dart';
import '../furniture_data.dart';

import 'package:flutter/foundation.dart';

class FurnitureDbService {
  static late Isar isar;

  static Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    
    // 安全打开数据库，避免重复打开报错
    if (Isar.instanceNames.isEmpty) {
      isar = await Isar.open(
        [FurnitureItemSchema],
        directory: dir.path,
      );
    } else {
      isar = Isar.getInstance()!;
    }

    // 检查数据量
    final count = await isar.furnitureItems.count();
    
    // 初始数据迁移或强制同步：如果数量不一致，或处于开发模式（为了方便实时调试配置），则重新导入
    if (kDebugMode || count != defaultFurnitureItems.length) {
      debugPrint('Furniture database syncing (Mode: ${kDebugMode ? "Debug/Force" : "Sync"})...');
      await isar.writeTxn(() async {
        await isar.furnitureItems.clear();
        await isar.furnitureItems.putAll(defaultFurnitureItems);
      });
    }
  }

  /// 获取所有家具
  static Future<List<FurnitureItem>> getAllItems() async {
    return await isar.furnitureItems.where().findAll();
  }

  /// 按分类获取家具
  static Future<List<FurnitureItem>> getItemsByCategory(String category) async {
    return await isar.furnitureItems.filter().categoryEqualTo(category).findAll();
  }
  
  /// 保存或更新家具
  static Future<void> saveItem(FurnitureItem item) async {
    await isar.writeTxn(() async {
      await isar.furnitureItems.put(item);
    });
  }
}
