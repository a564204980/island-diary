import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class SynchronizedCropRectTween extends Tween<Rect?> {
  final Rect beginPhysical;
  final Rect endPhysical;

  SynchronizedCropRectTween({
    required Rect beginNormalized,
    required Rect endNormalized,
    required this.beginPhysical,
    required this.endPhysical,
  }) : super(begin: beginNormalized, end: endNormalized);

  @override
  Rect lerp(double t) {
    if (begin == null || end == null) return super.lerp(t)!;

    final pNow = Rect.lerp(beginPhysical, endPhysical, t)!;

    final iwBegin = beginPhysical.width / begin!.width;
    final iwEnd = endPhysical.width / end!.width;
    final iwNow = ui.lerpDouble(iwBegin, iwEnd, t)!;

    final ihBegin = beginPhysical.height / begin!.height;
    final ihEnd = endPhysical.height / end!.height;
    final ihNow = ui.lerpDouble(ihBegin, ihEnd, t)!;

    final nwNow = pNow.width / iwNow;
    final nhNow = pNow.height / ihNow;

    final pcxBegin = beginPhysical.center.dx;
    final pcyBegin = beginPhysical.center.dy;
    final icxBegin = pcxBegin - begin!.center.dx * iwBegin;
    final icyBegin = pcyBegin - begin!.center.dy * ihBegin;

    final pcxEnd = endPhysical.center.dx;
    final pcyEnd = endPhysical.center.dy;
    final icxEnd = pcxEnd - end!.center.dx * iwEnd;
    final icyEnd = pcyEnd - end!.center.dy * ihEnd;

    final icxNow = ui.lerpDouble(icxBegin, icxEnd, t)!;
    final icyNow = ui.lerpDouble(icyBegin, icyEnd, t)!;

    final pcxNow = pNow.center.dx;
    final pcyNow = pNow.center.dy;

    final ncxNow = (pcxNow - icxNow) / iwNow;
    final ncyNow = (pcyNow - icyNow) / ihNow;

    return Rect.fromCenter(
      center: Offset(ncxNow, ncyNow),
      width: nwNow,
      height: nhNow,
    );
  }
}

enum CropHandle {
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
  top,
  bottom,
  left,
  right,
  inside,
  none,
}
