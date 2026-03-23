// --- 网格校准常量 ---
const int kGridRows = 19;
const int kGridCols = 19;
const double kGridCenterYFactorIPad = 0.40;
const double kGridCenterYFactorPhone = 0.29; 
const double kGridRotationDegree = -0.4; // 整体旋转角度
const double kGridTopTaper = 0.01; // 远端顶点 (0,0) 缩放
const double kGridBottomTaper = 0.06; // 近端顶点 (19,19) 缩放
const double kGridLeftTaper = 0; // 左端顶点 (0,19) 缩放 (调节左上角)
const double kGridRightTaper = 0; // 右端顶点 (19,0) 缩放 (调节右下角)
const double kSceneScaleFactor = 0.6; // 整个场景的缩放系数 (1.0 为默认，数值越大场景越大)
