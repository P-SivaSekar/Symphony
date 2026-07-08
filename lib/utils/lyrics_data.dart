import 'lyrics_parser.dart';

class LyricsData {
  static const String _adiPodiLrc = """
[00:00.00](Adi Podi - Intro Beats)
[00:05.00]Adi podi.. Adi podi..
[00:09.00]Vilaiyadi.. Vilaiyadi..
[00:13.00]Nee senjathellaam seriyadi..
[00:17.00]En vazhkaiyodu nee vilaiyadi..
[00:21.00]Pinnadi naan vandha appoellam
[00:25.00]Neeyum enna madhikkala di
[00:29.00]Aana unna thandi intha ulagathil
[00:33.00]Vera ponna pudikala di
[00:38.00]Aiyo pudikuthu di..
[00:41.00]Paithiyam ennaku pudikuthu di..
[00:45.00]Aiyo valikuthu di..
[00:48.00]Intha vali vera maari irukuthu di..
[00:53.00](Fast Instrumental Loop)
[01:05.00]Adi podi.. Vilaiyadi..
[01:10.00]Nee senjathellaam seriyadi..
[01:15.00](Outro beats fading)
""";

  static const String _vaathiComingLrc = """
[00:00.00](Vaathi Coming - Instrumental Intro)
[00:04.00]Tarukkula Triple-u Vuttaa
[00:08.00]Salpila Silpi Thottaa
[00:12.00]Thogurula Thagara Vuttaa
[00:16.00]Paguru Aguruthaan...
[00:20.00]Silkila Silki Vuttaa
[00:24.00]Kilpula Salttu Thotta
[00:28.00]Bijilila Bilpi Vuttaa
[00:32.00]Jettak Jarukkuthaan!
[00:36.00](Heavy Dappankuthu Beat Drop)
[00:44.00]Annan Vandhaa Atom Bomb-u Dummu
[00:48.00]Pilu Pilu Pilu Pilaami!
[00:52.00]Annan Vandhaa Atom Bomb-u Dummu
[00:56.00]Pilu Pilu Pilu Pilaami!
[01:00.00](Outro beats fading)
""";

  static const String _rowdyBabyLrc = """
[00:00.00](Rowdy Baby - Yuvan Shankar Raja Beats)
[00:06.00]Hey en goli sodavae
[00:11.00]En kari kozhambae
[00:16.00]Un kutty puppy naan
[00:20.00]Take me! Take me!
[00:25.00]Hey en silku satta
[00:30.00]Nee weightu katta
[00:35.00]Loveu sotta sotta
[00:40.00]Talk me! Talk me!
[00:45.00]Rowdy baby... Rowdy baby...
[00:50.00]Unakku naanthaane Rowdy baby...
[00:55.00]Rowdy baby... Rowdy baby...
[01:00.00](Yuvan energetic dance beat drop)
[01:10.00]Hey en goli sodavae...
[01:15.00](Outro fading)
""";

  static List<LyricLine> getLyricsForSong(String songId, String title, String artist) {
    final lowerTitle = title.toLowerCase();
    if (lowerTitle.contains('adi podi')) {
      return LyricsParser.parse(_adiPodiLrc);
    } else if (lowerTitle.contains('vaathi coming')) {
      return LyricsParser.parse(_vaathiComingLrc);
    } else if (lowerTitle.contains('rowdy baby')) {
      return LyricsParser.parse(_rowdyBabyLrc);
    }

    // Auto-generator for user uploaded/unknown songs so they always have nice lyrics!
    final List<LyricLine> generated = [
      LyricLine(time: Duration.zero, text: "(Intro Instrumental)"),
      LyricLine(time: const Duration(seconds: 5), text: "Playing: $title"),
      LyricLine(time: const Duration(seconds: 10), text: "By the artist: $artist"),
      LyricLine(time: const Duration(seconds: 16), text: "This is a premium synchronized lyrics demo"),
      LyricLine(time: const Duration(seconds: 22), text: "Feel the rhythm, let it guide you"),
      LyricLine(time: const Duration(seconds: 28), text: "Enjoy the beautiful visual scrolling"),
      LyricLine(time: const Duration(seconds: 35), text: "Tap any line here to seek to that part of the song!"),
      LyricLine(time: const Duration(seconds: 42), text: "(Awesome Musical Break)"),
      LyricLine(time: const Duration(seconds: 52), text: "Thank you for listening to Symphony"),
      LyricLine(time: const Duration(seconds: 58), text: "Your ultimate music experience"),
      LyricLine(time: const Duration(seconds: 64), text: "(Instrumental Outro)")
    ];
    return generated;
  }
}
