const int kGridRows = 24;
const int kGridCols = 24;
const double kGridCenterYFactorIPad = 0.42;
const double kGridCenterYFactorPhone = 0.42;
const double kGridRotationDegree = 0;
const double kGridAspectRatio = 0.57735; // tan(30°) ≈ 0.57735
const double kGridTopTaper = 0;
const double kGridBottomTaper = 0;
const double kGridLeftTaper = 0;
const double kGridRightTaper = 0;
const double kSceneScaleFactor = 2.0;
const int kWallGridHeight = 14;
const double kWallThickness = 0.6;

enum WallPattern { none, stripes, dualColor, lavenderStripes, wainscoting, clouds, gradient, sparkle, meltingDrips, greenHills, vintageFloral, ivySkirting, sakura, greenWoodPanels }
enum FloorPattern { none, herringbone, tripleHerringbone, plaid, randomWood, harlequin, terrazzo, cottonCandy }
const double kToolbarGlobalPadding = 45.0; // 工具栏与物品顶部的基础间距
