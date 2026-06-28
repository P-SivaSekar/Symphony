const fs = require('fs');
let content = fs.readFileSync('lib/main.dart', 'utf8');

const importStr = "import 'package:flutter_displaymode/flutter_displaymode.dart';\n\nvoid main() async {";
const replacementStr = "void main() async {";
content = content.replace(importStr, replacementStr);
content = "import 'package:flutter_displaymode/flutter_displaymode.dart';\n" + content;

fs.writeFileSync('lib/main.dart', content, 'utf8');
