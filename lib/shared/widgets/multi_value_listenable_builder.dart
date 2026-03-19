import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// 辅助组件：同时监听多个 ValueListenable
class MultiValueListenableBuilder extends StatelessWidget {
  final List<ValueListenable> listenables;
  final Widget Function(
    BuildContext context,
    List<dynamic> values,
    Widget? child,
  ) builder;
  final Widget? child;

  const MultiValueListenableBuilder({
    super.key,
    required this.listenables,
    required this.builder,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge(listenables),
      builder: (context, child) {
        // 精确映射每一个监听器的最新值
        final values = listenables.map((l) => l.value).toList();
        return builder(context, values, child);
      },
      child: child,
    );
  }
}
