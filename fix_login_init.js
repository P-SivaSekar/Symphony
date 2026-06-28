const fs = require('fs');
let code = fs.readFileSync('lib/providers/app_provider.dart', 'utf8');

code = code.replace(
  '  Future<String?> login(String email, String password) async {',
  `  Future<String?> login(String email, String password) async {
    if (Firebase.apps.isEmpty) {
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      } catch (e) {
        return 'Firebase init error: $e';
      }
    }`
);

code = code.replace(
  '  Future<String?> signup(String email, String password) async {',
  `  Future<String?> signup(String email, String password) async {
    if (Firebase.apps.isEmpty) {
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      } catch (e) {
        return 'Firebase init error: $e';
      }
    }`
);

fs.writeFileSync('lib/providers/app_provider.dart', code, 'utf8');
