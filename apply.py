
import json
with open('lib/features/home/presentation/widgets/photo_wall_card.dart', 'r', encoding='utf-8') as f:
    text = f.read()

with open(r'C:\Users\Lenovo\.gemini\antigravity-ide\brain\680202e1-15ef-4ca4-90c1-bc19281b89f5\.system_generated\logs\transcript_full.jsonl', 'r', encoding='utf-8') as f:
    for line in f:
        try:
            data = json.loads(line)
            if 'tool_calls' in data:
                for tc in data['tool_calls']:
                    if tc['name'] in ['replace_file_content', 'multi_replace_file_content'] and 'photo_wall_card.dart' in tc['args'].get('TargetFile', ''):
                        if tc['name'] == 'replace_file_content':
                            target = tc['args']['TargetContent']
                            repl = tc['args']['ReplacementContent']
                            if target in text:
                                text = text.replace(target, repl)
                            else: print('Failed match replace')
                        elif tc['name'] == 'multi_replace_file_content':
                            for chunk in tc['args']['ReplacementChunks']:
                                target = chunk['TargetContent']
                                repl = chunk['ReplacementContent']
                                if target in text:
                                    text = text.replace(target, repl)
                                else: print('Failed match multi')
        except Exception as e: pass

with open('lib/features/home/presentation/widgets/photo_wall_card.dart', 'w', encoding='utf-8') as f:
    f.write(text)
print('Applied previous conversation changes')
