import re
import os

def fix_errors():
    try:
        with open('analyze_output.txt', 'r', encoding='utf-16') as f:
            lines = f.readlines()
    except Exception as e:
        print('Could not read analyze_output.txt:', e)
        return

    # Dictionary mapping filepath -> { 'const_lines': set(), 'missing_colors_lines': set() }
    actions = {}

    for line in lines:
        line = line.strip()
        # format 1: lib/path.dart:123:45: Error: msg
        # format 2:  info - msg at lib/path.dart:123:45
        # format 3:  error • msg • lib/path.dart:123:45 • code
        
        filepath = None
        line_num = None
        msg = line.lower()

        match1 = re.search(r"^(lib[/\\].*\.dart):(\d+):\d+:\s+(?:Error|Warning):\s+(.*)", line, re.IGNORECASE)
        match2 = re.search(r"(lib[/\\].*\.dart):(\d+):\d+\s+-\s+(.*)", line)
        match3 = re.search(r"•\s+(lib[/\\].*\.dart):(\d+):\d+\s+•", line)

        if match1:
            filepath = match1.group(1)
            line_num = int(match1.group(2))
        elif match3:
            filepath = match3.group(1)
            line_num = int(match3.group(2))
        elif match2:
            filepath = match2.group(1)
            line_num = int(match2.group(2))

        if filepath and line_num:
            if filepath not in actions:
                actions[filepath] = {'const_lines': set(), 'missing_colors_lines': set()}
            
            if 'constant expression' in msg or 'const variables' in msg or 'invalid constant' in msg or 'colors' in msg:
                if 'colors' in msg and ('undefined' in msg or 'getter' in msg or 'not defined' in msg):
                    actions[filepath]['missing_colors_lines'].add(line_num)
                else:
                    actions[filepath]['const_lines'].add(line_num)

    # Apply fixes
    for filepath, data in actions.items():
        if not os.path.exists(filepath):
            continue
            
        with open(filepath, 'r', encoding='utf-8') as f:
            file_lines = f.readlines()

        if not file_lines: continue

        changed = False

        # 1. Remove consts (trace back up to 3 lines to find the word 'const ')
        for lnum in sorted(data['const_lines']):
            idx = lnum - 1
            if idx >= len(file_lines): continue
            
            # Simple heuristic: look for 'const ' in this line and the two lines above
            for offset in [0, -1, -2, -3]:
                check_idx = idx + offset
                if 0 <= check_idx < len(file_lines):
                    if 'const ' in file_lines[check_idx]:
                        file_lines[check_idx] = re.sub(r'\bconst\s+', '', file_lines[check_idx])
                        changed = True

        # 2. Add missing getter
        if data['missing_colors_lines']:
            for i in range(len(file_lines)):
                if 'extends State<' in file_lines[i] or 'extends ConsumerState<' in file_lines[i] or 'extends StatelessWidget' in file_lines[i]:
                    # Find the opening brace
                    for j in range(i, min(i+5, len(file_lines))):
                        if '{' in file_lines[j]:
                            file_lines.insert(j+1, "  FitNexoraThemeTokens get colors => context.fitTheme;\n")
                            changed = True
                            break
                    break

        if changed:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.writelines(file_lines)
            print(f'Fixed {filepath}')

fix_errors()
