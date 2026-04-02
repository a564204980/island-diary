// --- 网格校准常量 ---
const int kGridRows = 24;
const int kGridCols = 24;
const double kGridCenterYFactorIPad = 0.55;
const double kGridCenterYFactorPhone = 0.55;
const double kGridRotationDegree = 0; // 整体旋转角度
const double kGridAspectRatio = 0.5; // 恢复为 2:1 等距投影，以匹配大多数2D美术素材
const double kGridTopTaper = 0; // 远端顶点 (0,0) 缩放
const double kGridBottomTaper = 0; // 近端顶点 (24,24) 缩放
const double kGridLeftTaper = 0; // 左端顶点 (0,24) 缩放 (调节左上角)
const double kGridRightTaper = 0; // 右端顶点 (24,0) 缩放 (调节右下角)
const double kSceneScaleFactor = 1.2; // 扩大场景系数，防止边缘裁剪
const int kWallGridHeight = 12; // 墙面网格的高度 (单位：网格)
