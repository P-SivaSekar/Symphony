const fs = require('fs');
let code = fs.readFileSync('lib/providers/app_provider.dart', 'utf8');

// We want to replace the logic that shows local notifications.
// From:
//             if (!isFirstLoad && _notifications.length > previousLength) {
//               final newNotif = _notifications.first; // highest timestamp
// To:
//             final hasNewAdded = snapshot.docChanges.any((change) => change.type == DocumentChangeType.added);
//             if (!isFirstLoad && hasNewAdded && _notifications.isNotEmpty) {
//               final newNotif = _notifications.first;

code = code.replace(
  '            if (!isFirstLoad && _notifications.length > previousLength) {',
  '            final hasNewAdded = snapshot.docChanges.any((change) => change.type == DocumentChangeType.added);\n            if (!snapshot.metadata.isFromCache && !isFirstLoad && hasNewAdded && _notifications.isNotEmpty) {'
);

fs.writeFileSync('lib/providers/app_provider.dart', code, 'utf8');
