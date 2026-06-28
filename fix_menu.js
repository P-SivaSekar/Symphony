const fs = require('fs');
let code = fs.readFileSync('lib/main.dart', 'utf8');

code = code.replace(
  'backgroundColor: Colors.transparent,',
  'backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF121212) : Colors.white,'
);

fs.writeFileSync('lib/main.dart', code, 'utf8');
