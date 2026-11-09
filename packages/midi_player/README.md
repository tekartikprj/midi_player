# tekartik_midi_player

A Flutter plugin that plays a midi **file** (`.mid`) on Android
(`MediaPlayer`) and iOS (`AVMIDIPlayer`), with `playFile` also working on Linux
through the `timidity` or `wildmidi` command. It plays files from disk: it does
not parse, build or synthesize midi (build a file with
[tekartik_midi](https://github.com/tekartik/midi.dart), write it, play it).

## Getting started

Not on pub.dev, a git dependency:

```yaml
dependencies:
  tekartik_midi_player:
    git:
      url: https://github.com/tekartikprj/midi_player
      path: packages/midi_player
```

Play a file once (returns when it is over):

```dart
import 'package:tekartik_midi_player/midi_player.dart';

Future<void> playOnce(String path) async {
  await playFile(path);
}
```

Or keep a player to pause, seek and know when it ends:

```dart
import 'package:tekartik_midi_player/midi_player.dart';

Future<Player> start(String path) async {
  // loadFile registers the player: its onComplete stream fires at the end.
  var player = await loadFile(path);
  player.onComplete.listen((_) => player.close());
  await player.resume(); // play
  return player;
}
```

`Player` also has `pause()`, `seekTo(millis)`, `getDuration()` and
`getCurrentPosition()` (milliseconds, null when not loaded or closed),
`isPlaying()` and `close()` (always close a player you loaded).

### Platforms

| Platform | What works | Needs |
|---|---|---|
| Android | everything | nothing |
| iOS | everything | nothing: the plugin bundles its sound font (`sounds.sf2`, in the pod resources and the Swift package) |
| Linux | `playFile` only | `sudo apt install timidity` (or `wildmidi`) |
| macOS, Windows | nothing (`MissingPluginException`) | - |
| Web | does not build (the library imports `dart:io`) | - |

The path is a file path, not an asset key or a url: copy an asset or
downloaded bytes to a file first (`path_provider` + `dart:io`).

## Common mistakes

* A `Player()` (or `newPlayer`) never gets `onComplete`: create players with
  the top-level `loadFile(path)`.
* `Player.loadFile` twice on the same player throws a `StateError`: load a new
  player.
* `MidiPlayer.loadData(bytes)` is not implemented natively (it throws a
  `MissingPluginException`): write the bytes to a file and use `loadFile`.
* `playFile` cannot be paused: use `loadFile` for a song the user controls.

## Testing

Unit tests mock the `tekartik_midi_player` method channel (see
`test/midi_player_test.dart`). Real playback needs a device: the
`example/midi_player_example` app of the repo is a menu of every call.

More in the agent skill
[tekartik-midi-player-playback](skills/tekartik-midi-player-playback/SKILL.md).
