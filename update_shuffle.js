const fs = require('fs');
let code = fs.readFileSync('lib/services/player_service.dart', 'utf8');

const target = `    if (validSongs.isEmpty) return;
    _playlist = validSongs;`;

const replacement = `    if (validSongs.isEmpty) return;
    
    // Auto-enable shuffle if the queue was previously empty
    if (_playlist.isEmpty) {
      await _audioPlayer.setShuffleModeEnabled(true);
    }
    
    _playlist = validSongs;`;

code = code.replace(target, replacement);
fs.writeFileSync('lib/services/player_service.dart', code, 'utf8');
