// ignore_for_file: avoid_print

import 'package:process_run/shell.dart';

final _hasWildmidi = () async {
  try {
    await run('wildmidi --version');
    return true;
  } catch (_) {
    print(
      'please install wildmidi for midi playback: sudo apt install wildmidi',
    );
    return false;
  }
}();

final _hasTimidify = () async {
  try {
    await run('timidity --version');
    return true;
  } catch (_) {
    print(
      'please install timidity for midi playback: sudo apt install timidity',
    );
    return false;
  }
}();

Future<void> linuxPlayMidiFile(String path) async {
  if (await _hasTimidify) {
    await linuxPlayMidiFileUsingTimidity(path);
  } else {
    // To test.
    await linuxPlayMidiFileUsingWildmidi(path);
  }
}

/// Warning: Somehow does not work embedded in a flutter app...
Future<void> linuxPlayMidiFileUsingWildmidi(String path) async {
  if (await _hasWildmidi) {
    try {
      await run('wildmidi ${shellArgument(path)}');
    } catch (e) {
      print('error playing file $path: $e');
    }
  }
}

Future<void> linuxPlayMidiFileUsingTimidity(String path) async {
  if (await _hasTimidify) {
    try {
      await run('timidity ${shellArgument(path)}');
    } catch (e) {
      print('error playing file $path: $e');
    }
  }
}
