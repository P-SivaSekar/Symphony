const fs = require('fs');
let code = fs.readFileSync('lib/ui/yt_music_player.dart', 'utf8');

const builderRegex = /builder: \(height, percentage\) \{/;
code = code.replace(builderRegex, `builder: (height, percentage) {
        Future.microtask(() {
          playerExpandProgress.value = percentage;
        });`);

fs.writeFileSync('lib/ui/yt_music_player.dart', code, 'utf8');
