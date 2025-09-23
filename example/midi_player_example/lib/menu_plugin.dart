import 'dart:async';

import 'package:flutter/services.dart';
import 'package:tekartik_midi_player/midi_player.dart';
import 'package:tekartik_test_menu_flutter/test.dart';

Future menuPlugin() async {
  group('plugin', () {
    test('platform', () async {
      write((await MidiPlayer.platformVersion)!);
    });
    group('player', () {
      test('load dummy file', () async {
        // await MidiPlayer.devSetDebugModeOn();
        var filePath = 'dummy path';
        try {
          await loadFile(filePath);
          fail('should fail');
        } on PlatformException catch (e) {
          write(e);
        }
        write('loaded file $filePath');
      });
    });
  });
}
