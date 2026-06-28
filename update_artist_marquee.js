const fs = require('fs');
let code = fs.readFileSync('lib/ui/player_screen.dart', 'utf8');

const targetArtistText = `                                          Text(
                                            qSong.artist,
                                            style: TextStyle(
                                              fontSize: 18,
                                              color: textColor.withOpacity(0.7),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),`;

const replacementArtistMarquee = `                                          qSong.artist.length > 25
                                              ? SizedBox(
                                                  height: 22,
                                                  child: Marquee(
                                                    text: qSong.artist,
                                                    style: TextStyle(
                                                      fontSize: 18,
                                                      color: textColor.withOpacity(0.7),
                                                    ),
                                                    scrollAxis: Axis.horizontal,
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    blankSpace: 40.0,
                                                    velocity: 30.0,
                                                  ),
                                                )
                                              : Text(
                                                  qSong.artist,
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    color: textColor.withOpacity(0.7),
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),`;

if (code.includes(targetArtistText)) {
    code = code.replace(targetArtistText, replacementArtistMarquee);
    fs.writeFileSync('lib/ui/player_screen.dart', code, 'utf8');
    console.log('SUCCESS');
} else {
    console.log('TARGET NOT FOUND');
}
