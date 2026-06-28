const fs = require('fs');
let content = fs.readFileSync('lib/ui/sliding_player_panel.dart', 'utf8');

const target = `                                    onPressed: playerService.hasNext
                                        ? () => playerService.playNext()
                  if (collapseProgress > 0)`;

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

if (content.includes(target)) {
    content = content.replace(target, replacement);
    fs.writeFileSync('lib/ui/sliding_player_panel.dart', content, 'utf8');
    console.log('SUCCESS');
} else {
    console.log('TARGET NOT FOUND');
}
