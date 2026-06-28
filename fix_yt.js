const fs = require('fs');
let code = fs.readFileSync('lib/ui/yt_music_player.dart', 'utf8');

code = code.replace(
  '  void _toggle() {',
  '  void _toggle() {\n    FocusManager.instance.primaryFocus?.unfocus();'
);

code = code.replace(
  '  void _handleVerticalUpdate(DragUpdateDetails details) {',
  '  void _handleVerticalUpdate(DragUpdateDetails details) {\n    FocusManager.instance.primaryFocus?.unfocus();'
);

// also fix the "slight swipe from mini player bottom to top strucks the cover image slightly extended"
// That means the user swiped UP slightly from the mini player and let go, so velocity is small negative, but fraction is small.
// if (_controller.value >= 0.5 || details.primaryVelocity! < -500)
// If they swiped UP, velocity is negative. If it's a slight swipe, velocity might be -100, which is NOT < -500.
// So it goes to `else { reverse() }` and collapses! But wait, if they say it gets STUCK, it means the animation doesn't finish!
// Why wouldn't it finish?
// Because in _handleVerticalUpdate, fractionDragged is details.primaryDelta! / screenHeight.
// If _controller.value goes out of bounds (<0 or >1), _controller throws an error or clamps?
// AnimationController automatically clamps to 0.0 - 1.0!
// So it shouldn't get stuck, UNLESS they hold it!

code = code.replace(
  '    if (_controller.value >= 0.5 || details.primaryVelocity! < -500) {',
  '    if (_controller.value >= 0.2 || (details.primaryVelocity != null && details.primaryVelocity! < -300)) {'
);

fs.writeFileSync('lib/ui/yt_music_player.dart', code, 'utf8');
