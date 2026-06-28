import re
with open('lib/ui/home_screen.dart', 'r') as f:
    text = f.read()

# Fix the accidental replace of textColor definition
text = text.replace('final Colors.white = theme.colorScheme.onSurface;', 'final textColor = theme.colorScheme.onSurface;')
# Fix textColor used in other widgets
text = re.sub(r'const Text\((.*?), style: const TextStyle\(color: Colors\.white\)\)', r'Text(\1, style: TextStyle(color: theme.colorScheme.onSurface))', text)
text = re.sub(r'const TextStyle\(color: Colors\.white\)', r'TextStyle(color: Theme.of(context).colorScheme.onSurface)', text)
text = re.sub(r'const Text\(([^,]+),\n\s*style: const TextStyle\(color: Colors\.white\)', r'Text(\1,\n            style: TextStyle(color: Theme.of(context).colorScheme.onSurface)', text)
text = re.sub(r'const Text\(([^,]+),\n\s*style: TextStyle\(color: Colors\.white\)', r'Text(\1,\n            style: TextStyle(color: Theme.of(context).colorScheme.onSurface)', text)

# For hint styles and opacity
text = re.sub(r'TextStyle\(color: Colors\.white\.withOpacity', r'TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity', text)
text = re.sub(r'style: TextStyle\(color: Colors\.white\)', r'style: TextStyle(color: Theme.of(context).colorScheme.onSurface)', text)
text = re.sub(r'color: Colors\.white,', r'color: Theme.of(context).colorScheme.onSurface,', text)

with open('lib/ui/home_screen.dart', 'w') as f:
    f.write(text)
