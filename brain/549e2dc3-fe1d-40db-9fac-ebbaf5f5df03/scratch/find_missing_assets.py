import os
import re

config_dir = r'd:\project\island_diary\lib\features\record\data\furniture'
assets_dir = r'd:\project\island_diary'

# Regex to find FurnitureItem blocks (approximate)
# Looking for FurnitureItem( ... ) and its imagePath
pattern = re.compile(r'FurnitureItem\(\s*id:\s*\'(.*?)\',\s*name:\s*\'(.*?)\',[\s\S]*?imagePath:\s*\'(.*?)\',', re.MULTILINE)

missing_items = []

for filename in os.listdir(config_dir):
    if filename.endswith('.dart'):
        filepath = os.path.join(config_dir, filename)
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
            matches = pattern.finditer(content)
            for match in matches:
                item_id = match.group(1)
                item_name = match.group(2)
                image_path = match.group(3)
                
                full_image_path = os.path.join(assets_dir, image_path.replace('/', os.sep))
                if not os.path.exists(full_image_path):
                    missing_items.append({
                        'id': item_id,
                        'name': item_name,
                        'path': image_path,
                        'file': filename
                    })

for item in missing_items:
    print(f"File: {item['file']} | ID: {item['id']} | Name: {item['name']} | Path: {item['path']}")
