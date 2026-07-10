class ApiConstants {
  static const String baseUrl = 'http://192.168.10.3:8080';
  static const String uploadEndpoint = '$baseUrl/api/v1/files/upload';

  // ================= 预警排名模块 =================
  /// 预警排名接口
  /// Method: GET
  /// Path: /ai/regularReport/warn/rank
  /// Params:
  /// - [ClaimQueryDTO] dto (timeType, queryDate, startDate, endDate, pageNum, pageSize)
  /// - [int] type (排名类型: 1-涉事地址, 0-承办单位)
  static const String warnRankEndpoint = '$baseUrl/ai/regularReport/warn/rank';
}
