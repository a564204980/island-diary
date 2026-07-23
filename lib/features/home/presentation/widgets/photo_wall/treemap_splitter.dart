import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 二叉切分树叶子节点
class TreemapLeaf {
  final int index;
  final Rect rect;

  TreemapLeaf({required this.index, required this.rect});
}

/// 矩形二叉树切分算法引擎 (Guillotine Treemap Split Layout)
class TreemapSplitter {
  static List<TreemapLeaf> computeLeaves(Rect bounds, List<int> indices, int seed) {
    final List<TreemapLeaf> leaves = [];
    final rand = math.Random(seed);

    void splitNode(Rect currentRect, List<int> currentIndices) {
      if (currentIndices.isEmpty) return;
      if (currentIndices.length == 1) {
        leaves.add(TreemapLeaf(index: currentIndices.first, rect: currentRect));
        return;
      }

      final aspect = currentRect.width / currentRect.height;
      final splitVertically = aspect > 1.1 ? true : (aspect < 0.9 ? false : rand.nextBool());

      final half = (currentIndices.length / 2).round();
      final leftIndices = currentIndices.sublist(0, half);
      final rightIndices = currentIndices.sublist(half);

      final ratio = (leftIndices.length / currentIndices.length) + (rand.nextDouble() - 0.5) * 0.12;
      final clampedRatio = ratio.clamp(0.35, 0.65);

      if (splitVertically) {
        final leftW = currentRect.width * clampedRatio;
        final rectLeft = Rect.fromLTWH(currentRect.left, currentRect.top, leftW, currentRect.height);
        final rectRight = Rect.fromLTWH(currentRect.left + leftW, currentRect.top, currentRect.width - leftW, currentRect.height);
        splitNode(rectLeft, leftIndices);
        splitNode(rectRight, rightIndices);
      } else {
        final topH = currentRect.height * clampedRatio;
        final rectTop = Rect.fromLTWH(currentRect.left, currentRect.top, currentRect.width, topH);
        final rectBottom = Rect.fromLTWH(currentRect.left, currentRect.top + topH, currentRect.width, currentRect.height - topH);
        splitNode(rectTop, leftIndices);
        splitNode(rectBottom, rightIndices);
      }
    }

    splitNode(bounds, indices);
    return leaves;
  }
}
