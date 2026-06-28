const fs = require('fs');
const lines = fs.readFileSync('lib/main.dart', 'utf8').split('\n');
console.log('main() at ' + lines.findIndex(l => l.includes('void main()')));
console.log('pendingAdminTabNotifier at ' + lines.findIndex(l => l.includes('pendingAdminTabNotifier = ValueNotifier')));
