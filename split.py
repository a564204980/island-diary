import os

path = r'd:\project\island_diary\lib\features\statistics\presentation\pages\statistics_page.dart'
dest = r'd:\project\island_diary\lib\features\statistics\presentation\widgets\statistics_bento_fragments.dart'

with open(path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

start_idx = -1
for i, line in enumerate(lines):
    if '// ============== BENTO COMPONENTS ==============' in line:
        start_idx = i
        break

if start_idx != -1:
    bento_lines = lines[start_idx:]
    
    # Trim trailing braces
    for i in range(len(bento_lines)-1, -1, -1):
        if bento_lines[i].strip() == '}':
            bento_lines = bento_lines[:i]
            break

    fragment_content = "part of '../pages/statistics_page.dart';\n\n"
    fragment_content += "extension StatisticsBentoFragments on _StatisticsPageState {\n"
    fragment_content += "".join(bento_lines) + "}\n"

    with open(dest, 'w', encoding='utf-8') as f:
        f.write(fragment_content)

    import_insert_idx = 0
    for i, line in enumerate(lines[:start_idx]):
        if 'class StatisticsPage' in line or 'enum StatTimeRange' in line:
            import_insert_idx = i
            break

    final_page_lines = lines[:import_insert_idx]
    final_page_lines.append("part '../widgets/statistics_bento_fragments.dart';\n\n")
    final_page_lines.extend(lines[import_insert_idx:start_idx])
    final_page_lines.append("}\n")

    with open(path, 'w', encoding='utf-8') as f:
        f.write("".join(final_page_lines))
        
    print('Split successful')
else:
    print('Failed to find boundary')
