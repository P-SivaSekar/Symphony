const fs = require('fs');
let code = fs.readFileSync('lib/ui/home_screen.dart', 'utf8');

// Replace SliverGridDelegateWithMaxCrossAxisExtent with FixedCrossAxisCount
code = code.replace(
  'const SliverGridDelegateWithMaxCrossAxisExtent(',
  'const SliverGridDelegateWithFixedCrossAxisCount('
);

code = code.replace(
  'maxCrossAxisExtent: 150,',
  'crossAxisCount: 3,'
);

// Add bottom padding to SliverPadding
code = code.replace(
  '                              bottom: 20,',
  '                              bottom: 120,'
);

fs.writeFileSync('lib/ui/home_screen.dart', code, 'utf8');
