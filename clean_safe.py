import re
import os
from collections import defaultdict

def main():
    content = ""
    try:
        with open('analyze_output.txt', 'r', encoding='utf-16') as f:
            content = f.read()
    except Exception:
        with open('analyze_output.txt', 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read()

    file_to_lines = defaultdict(set)
    for line in content.splitlines():
        if "unused_local_variable" in line or "unused_import" in line or "duplicate_import" in line or "Undefined name 'colors'" in line:
            m = re.search(r'(lib[/\\][^:]*\.dart):(\d+):\d+', line, re.IGNORECASE)
            if m:
                filepath = m.group(1).replace('\\', '/')
                line_num = int(m.group(2))
                file_to_lines[filepath].add(line_num)
        
    for filepath, lines in file_to_lines.items():
        if not os.path.exists(filepath):
            continue
        try:
            with open(filepath, 'r', encoding='utf-8') as f:
                file_lines = f.readlines()
                
            for lineno in sorted(list(lines), reverse=True):
                idx = lineno - 1
                if 0 <= idx < len(file_lines):
                    line_text = file_lines[idx].strip()
                    # Safe removal
                    if line_text.startswith("final colors =") or line_text.startswith("FitNexoraThemeTokens get colors") or line_text.startswith("import "):
                        file_lines[idx] = ""
                    
            with open(filepath, 'w', encoding='utf-8') as f:
                f.writelines(file_lines)
            print(f"Cleaned {filepath}")
        except Exception as e:
            print(f"Error processing {filepath}: {e}")

if __name__ == '__main__':
    main()
