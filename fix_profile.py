import re

with open('lib/ui/profile_screen.dart', 'r') as f:
    content = f.read()

# Replace the broken part
pattern = r"(\s+color: isDark\s+\?\s+Colors\.black\.withOpacity\(0\.2\)\s+\};\s+Navigator\.push\()"

replacement = """                          ? Colors.black.withOpacity(0.2)
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
                                        Navigator.push("""

# Try generic replacement based on known context from the view_file:
# The current file has:
# 561:                       color: isDark
# 562:                           ? Colors.black.withOpacity(0.2)
# 563:                                         };
# 564:                                         Navigator.push(

pattern2 = r"(\s+color: isDark\s*\n\s*\?\s*Colors\.black\.withOpacity\(0\.2\)\s*\n\s*\};\s*\n\s*Navigator\.push\()"

new_content = re.sub(pattern2, r"\n                      color: isDark" + "\n" + replacement, content)

if content == new_content:
    print("Failed to replace!")
else:
    with open('lib/ui/profile_screen.dart', 'w') as f:
        f.write(new_content)
    print("Fixed profile_screen.dart")
