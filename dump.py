with open('lib/ui/profile_screen.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()
for i in range(670, 685):
    print(f"{i+1}: {repr(lines[i])}")
