import re
from collections import defaultdict
import os

def main():
    content = ""
    try:
        with open('analyze_output.txt', 'r', encoding='utf-16') as f:
            content = f.read()
    except Exception:
        with open('analyze_output.txt', 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read()

    file_to_lines = defaultdict(set)
    for match in re.finditer(r'(lib[/\\][^:]*\.dart):(\d+):\d+', content, re.IGNORECASE):
        filepath = match.group(1)
        line_num = int(match.group(2))
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
                    # For safety, make sure it looks like an import or variable declaration
                    line_text = file_lines[idx].strip()
                    if 'import' in line_text or 'colors' in line_text or 'FitNexoraThemeTokens' in line_text:
                        file_lines[idx] = ""
                    
            with open(filepath, 'w', encoding='utf-8') as f:
                f.writelines(file_lines)
            print(f"Cleaned {filepath}")
        except Exception as e:
            print(f"Error processing {filepath}: {e}")

if __name__ == '__main__':
    main()
