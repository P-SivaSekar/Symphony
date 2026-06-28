const fs = require('fs');
let code = fs.readFileSync('lib/main.dart', 'utf8');

const regex = /    return Future\.value\(true\);\s*\);\s*\} catch \(e\) \{\s*if \(Firebase\.apps\.isEmpty\) \{\s*try \{\s*await Firebase\.initializeApp\(\);/;

const replacement = `    return Future.value(true);
  });
}

final ValueNotifier<String?> pendingSongPlayNotifier = ValueNotifier(null);
final ValueNotifier<int?> pendingAdminTabNotifier = ValueNotifier(null);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (!kIsWeb && Platform.isAndroid) {
    try {
      await FlutterDisplayMode.setHighRefreshRate();
    } catch (e) {
      debugPrint('Error setting high refresh rate: $e');
    }
  }

  if (Firebase.apps.isEmpty) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (e) {
      if (Firebase.apps.isEmpty) {
        try {
          await Firebase.initializeApp();`;

if (regex.test(code)) {
    code = code.replace(regex, replacement);
    fs.writeFileSync('lib/main.dart', code, 'utf8');
    console.log('SUCCESS');
} else {
    console.log('TARGET NOT FOUND');
}
