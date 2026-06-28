const fs = require('fs');
let content = fs.readFileSync('lib/ui/profile_screen.dart', 'utf-8');

const target = `                      color: isDark
                          ? Colors.black.withOpacity(0.2)
                                        };
                                        Navigator.push(`;

const replacement = `                      color: isDark
                          ? Colors.black.withOpacity(0.2)
                          : theme.colorScheme.surface,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                      border: isDark
                          ? null
                          : const Border(
                              top: BorderSide(color: Colors.black12),
                            ),
                    ),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 120),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                if (!kIsWeb) ...[
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        final downloadedPlaylist = {
                                          'name': 'Downloads',
                                          'songs': appProvider.downloadedSongs,
                                        };
                                        Navigator.push(`;

content = content.replace(target, replacement);
fs.writeFileSync('lib/ui/profile_screen.dart', content);
console.log("Done");
