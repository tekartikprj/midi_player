import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tekartik_midi/midi.dart';
import 'package:tekartik_midi/midi_writer.dart';
import 'package:tekartik_midi_player/midi_player.dart';

// ignore: depend_on_referenced_packages
import 'package:tekartik_test_menu_flutter/test.dart';

import 'menu_plugin.dart';

Future main() async {
  mainMenuFlutter(() {
    Future<String> loadPopFile() async {
      var data = await rootBundle.load(join('assets', 'pop.mid'));
      var bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      var path = (await getApplicationDocumentsDirectory()).path;

      var filePath = join(path, 'file.mid');
      await File(filePath).writeAsBytes(bytes, flush: true);
      return filePath;
    }

    MidiFile creatSampleMidiFile() {
      var file = MidiFile();
      file.fileFormat = MidiFile.formatMultiTrack;
      file.ppq = 240;

      var track = MidiTrack();
      track.addEvent(0, TimeSigEvent(4, 4));
      track.addEvent(0, TempoEvent.bpm(120));
      track.addEvent(0, EndOfTrackEvent());
      file.addTrack(track);

      track = MidiTrack();
      track.addEvent(0, ProgramChangeEvent(1, 25));
      track.addEvent(0, NoteOnEvent(1, 54, 127));
      track.addEvent(240, NoteOnEvent(1, 56, 127));
      track.addEvent(240, NoteOnEvent(1, 58, 127));
      track.addEvent(240, NoteOffEvent(1, 54, 127));
      track.addEvent(0, NoteOffEvent(1, 58, 127));
      track.addEvent(480, NoteOffEvent(1, 58, 127));
      // track.add(new Event.NoteOn(0, 1, 42, 127));
      // track.add(new Event.NoteOff(480, 1, 42, 127));
      // // track.add(new Event.NoteOn(0, 1, 42, 127));
      // track.add(new Event.NoteOff(120, 1, 42, 127));
      track.addEvent(0, EndOfTrackEvent());
      file.addTrack(track);
      return file;
    }

    Future<String> loadNotesFile() async {
      var file = creatSampleMidiFile();

      var directory = await getApplicationDocumentsDirectory();
      await Directory(directory.path).create(recursive: true);
      var path = join(directory.path, 'notes.mid');
      await File(path).writeAsBytes(FileWriter.fileData(file), flush: true);
      return path;
    }

    menu('plugin', () {
      test('platform', () async {
        write((await MidiPlayer.platformVersion)!);
      });
      test('setDebugModeOn', () async {
        await MidiPlayer.setDebugModeOn(true);
        write('done');
      });
      menu('player', () {
        menu('notes', () {
          test('playFile', () async {
            // await MidiPlayer.devSetDebugModeOn();

            var filePath = await loadNotesFile();

            write('playing file');
            await playFile(filePath);
            write('done playing file');
          });
        });
        menu('single', () {
          Player? player;
          Future writeCurrentPosition() async {
            write(
              'getCurrentPosition ${await player?.getCurrentPosition()} ${await player?.isPlaying()}',
            );
          }

          Future seekTo(int millis) async {
            await writeCurrentPosition();
            await player?.seekTo(millis);
            await writeCurrentPosition();
          }

          item('load', () async {
            player = await _load(player, loadPopFile);
            await writeCurrentPosition();
          });
          item('load_and_play', () async {
            player = await _load(player, loadPopFile);
            await writeCurrentPosition();
            await player?.resume();
            await writeCurrentPosition();
          });

          item('resume', () async {
            await writeCurrentPosition();
            await player?.resume();
            await writeCurrentPosition();
          });
          item('pause', () async {
            await writeCurrentPosition();
            await player?.pause();
            await writeCurrentPosition();
          });
          item('close', () async {
            await player?.close();
          });
          item('seek -1000', () async {
            await seekTo(-1000);
          });

          item('seek 50000', () async {
            await seekTo(50000);
          });
          item('seek 10000000', () async {
            await seekTo(100000000);
          });
          item('duration', () async {
            write('Duration ${await player?.getDuration()}');
          });
          item('getCurrentPosition', () async {
            await writeCurrentPosition();
          });

          item('getCurrentPosition100', () async {
            for (var i = 0; i < 100; i++) {
              await writeCurrentPosition();
            }
          });
        });
        test('play pop for 5s', () async {
          // await MidiPlayer.devSetDebugModeOn();

          var filePath = await loadPopFile();

          var player = await loadFile(filePath);
          await player.resume();
          await Future<void>.delayed(const Duration(milliseconds: 5000));
          await player.pause();
          await player.close();
        });
      });
    });
    menuPlugin();
  }, showConsole: true);
}

Future<Player> _load(
  Player? player,
  Future<String> Function() loadPopFile,
) async {
  // await MidiPlayer.devSetDebugModeOn();
  await player?.close();
  var filePath = await loadPopFile();

  player = await loadFile(filePath);
  player.onComplete.listen((_) {
    write('onComplete');
  });
  return player;
}
