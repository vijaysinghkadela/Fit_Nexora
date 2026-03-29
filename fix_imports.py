import os
import re

def fix_codebase():
    base_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'lib')
    
    for root, dirs, files in os.walk(base_dir):
        for filename in files:
            if not filename.endswith('.dart'): continue
            filepath = os.path.join(root, filename)
            
            with open(filepath, 'r', encoding='utf-8') as f:
                content = f.read()
                
            original_content = content
            
            # 1. Add missing imports
            if 'FitNexoraThemeTokens' in content or 'context.fitTheme' in content or 'colors.' in content:
                if 'package:gymos_ai/config/theme.dart' not in content and 'config/theme.dart' not in content:
                    content = "import 'package:gymos_ai/config/theme.dart';\n" + content
                if 'package:gymos_ai/core/extensions.dart' not in content and 'core/extensions.dart' not in content:
                    content = "import 'package:gymos_ai/core/extensions.dart';\n" + content
            
            # 2. Fix specific `workouts_screen.dart` field initializer issue
            if 'workouts_screen.dart' in filepath:
                # In workouts_screen.dart, there is heavily nested structure.
                # Let's find: `final items = [` or similar, and change it to be a getter or build method variable.
                # Or wait, if there are properties like `Color color = colors.brand;`
                # Let's just blindly replace `colors.` with `context.fitTheme.` in field initializers? No, you can't access `context` either!
                pass # We will fix workouts_screen.dart manually via replace_file_content

            # 3. Add missing GETTER to classes that extend State or CustomPainters if they use colors.
            # Example: class _ProRingPainter extends CustomPainter
            if 'colors.' in content and 'FitNexoraThemeTokens get colors' not in content and 'final colors' not in content:
                # Inject getter into State classes
                content = re.sub(r'(class \w+ extends State<[^>]+>\s*\{)', r'\1\n  FitNexoraThemeTokens get colors => context.fitTheme;\n', content)

            if original_content != content:
                with open(filepath, 'w', encoding='utf-8') as f:
                    f.write(content)
                print(f"Fixed imports/getters in {filepath}")

fix_codebase()
