
import json
with open(r'C:\Users\Lenovo\.gemini\antigravity-ide\brain\680202e1-15ef-4ca4-90c1-bc19281b89f5\.system_generated\logs\transcript_full.jsonl', 'r', encoding='utf-8') as f:
    for line in f:
        try:
            data = json.loads(line)
            if 'tool_calls' in data:
                for tc in data['tool_calls']:
                    if tc['name'] == 'write_to_file' and 'photo_wall_card.dart' in tc['args'].get('TargetFile', ''):
                        print('Found write_to_file!')
                        # Let's save it
                        with open('lib/features/home/presentation/widgets/photo_wall_card.dart', 'w', encoding='utf-8') as fw:
                            fw.write(tc['args']['CodeContent'])
        except Exception as e: pass
print('Done')
