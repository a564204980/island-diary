
import 'package:island_diary/shared/widgets/diary_entry/utils/emoji_mapping.dart';

void main() {
  print('Pattern: ${EmojiMapping.pattern}');
  
  final text = '[shuangjian:呜呜]';
  final chunks = EmojiMapping.parseText(text);
  print('Testing: $text');
  for (var c in chunks) {
    print('Chunk: "${c.text}", isEmoji: ${c.isEmoji}, path: ${c.emojiPath}');
  }
}
