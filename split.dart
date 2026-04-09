import 'dart:io';

void main() {
  final path = r'd:\project\island_diary\lib\features\statistics\presentation\pages\statistics_page.dart';
  final dest = r'd:\project\island_diary\lib\features\statistics\presentation\widgets\statistics_bento_fragments.dart';

  final file = File(path);
  final lines = file.readAsLinesSync();

  int startIdx = -1;
  for (int i = 0; i < lines.length; i++) {
    if (lines[i].contains('// ============== BENTO COMPONENTS ==============')) {
      startIdx = i;
      break;
    }
  }

  if (startIdx != -1) {
    var bentoLines = lines.sublist(startIdx);
    
    for (int i = bentoLines.length - 1; i >= 0; i--) {
      if (bentoLines[i].trim() == '}') {
        bentoLines = bentoLines.sublist(0, i);
        break;
      }
    }

    var fragmentContent = "part of '../pages/statistics_page.dart';\n\n";
    fragmentContent += "extension StatisticsBentoFragments on _StatisticsPageState {\n";
    fragmentContent += bentoLines.join('\n') + "\n}\n";

    File(dest).writeAsStringSync(fragmentContent);

    int importInsertIdx = 0;
    for (int i = 0; i < startIdx; i++) {
      if (lines[i].contains('class StatisticsPage') || lines[i].contains('enum StatTimeRange')) {
        importInsertIdx = i;
        break;
      }
    }

    final finalPageLines = lines.sublist(0, importInsertIdx);
    finalPageLines.add("import 'package:island_diary/features/statistics/presentation/widgets/glass_bento.dart';");
    finalPageLines.add("part '../widgets/statistics_bento_fragments.dart';\n");
    finalPageLines.addAll(lines.sublist(importInsertIdx, startIdx));
    finalPageLines.add("}\n");

    file.writeAsStringSync(finalPageLines.join('\n'));
    print('Split successful');
  } else {
    print('Failed to find boundary');
  }
}
