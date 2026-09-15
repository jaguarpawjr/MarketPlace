import os
import re

dir_path = 'c:/Users/HP/Downloads/marketplace/lib'

count = 0
for root, _, files in os.walk(dir_path):
    for file in files:
        if file.endswith('.dart'):
            filepath = os.path.join(root, file)
            with open(filepath, 'r', encoding='utf-8') as f:
                content = f.read()
            
            if 'print(' in content:
                new_content = re.sub(r'\bprint\(', 'debugPrint(', content)
                if new_content != content:
                    # check if we need to import foundation
                    if 'package:flutter/foundation.dart' not in new_content and 'package:flutter/material.dart' not in new_content:
                        # try to find the last import and insert after it
                        imports = re.findall(r'^import .*;', new_content, re.MULTILINE)
                        if imports:
                            last_import = imports[-1]
                            new_content = new_content.replace(last_import, last_import + "\nimport 'package:flutter/foundation.dart';")
                        else:
                            new_content = "import 'package:flutter/foundation.dart';\n" + new_content
                    
                    with open(filepath, 'w', encoding='utf-8') as f:
                        f.write(new_content)
                    print(f'Updated {filepath}')
                    count += 1

print(f'Total updated: {count}')
