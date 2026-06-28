const fs = require('fs');
let code = fs.readFileSync('lib/main.dart', 'utf8');

code = code.replace(
  '    } catch (e) {\n      if (Firebase.apps.isEmpty) {',
  '    } catch (e) {\n      print("Firebase primary initialization error: $e");\n      if (Firebase.apps.isEmpty) {'
);

fs.writeFileSync('lib/main.dart', code, 'utf8');
