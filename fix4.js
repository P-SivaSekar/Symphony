const fs = require('fs');
let content = fs.readFileSync('lib/ui/sliding_player_panel.dart', 'utf8');

const regex = /                                    onPressed: playerService.hasNext[\s\S]*?\? \(\) => playerService.playNext\(\)[\s\S]*?if \(collapseProgress > 0\)/;

const replacement = `                                    onPressed: playerService.hasNext
                                        ? () => playerService.playNext()
                                        : null,
                                  ),
                                ],
                              ),
                              const SizedBox(width: 4),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Lever UI
                  if (collapseProgress > 0)`;

if (regex.test(content)) {
    content = content.replace(regex, replacement);
    fs.writeFileSync('lib/ui/sliding_player_panel.dart', content, 'utf8');
    console.log('SUCCESS');
} else {
    console.log('TARGET NOT FOUND');
}
