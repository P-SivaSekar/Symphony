const fs = require('fs');
let code = fs.readFileSync('lib/providers/app_provider.dart', 'utf8');

if (!code.includes('firebase_options.dart')) {
    code = code.replace(
        "import 'package:firebase_auth/firebase_auth.dart';",
        "import 'package:firebase_auth/firebase_auth.dart';\nimport '../firebase_options.dart';"
    );
    fs.writeFileSync('lib/providers/app_provider.dart', code, 'utf8');
}
