// --- 网格校准常量 ---
const int kGridRows = 24;
const int kGridCols = 24;
const double kGridCenterYFactorIPad = 0.55;
const double kGridCenterYFactorPhone = 0.55;
const double kGridRotationDegree = 0; // 整体旋转角度
const double kGridAspectRatio = 0.5; // 26.5度视角 (2:1 比例)
const double kGridTopTaper = 0; // 远端顶点 (0,0) 缩放
const double kGridBottomTaper = 0; // 近端顶点 (24,24) 缩放
const double kGridLeftTaper = 0; // 左端顶点 (0,24) 缩放 (调节左上角)
const double kGridRightTaper = 0; // 右端顶点 (24,0) 缩放 (调节右下角)
const double kSceneScaleFactor = 1.2; // 扩大场景系数，防止边缘裁剪
const int kWallGridHeight = 14; // 墙面网格的高度 (单位：网格)
const double kWallThickness = 0.6; // 墙体厚度 (单位：网格)
