import 'dart:async';
import 'dart:io';

import 'package:synchronized/synchronized.dart';
import 'package:tekartik_midi_player/src/midi_player_linux.dart';

import 'src/constant.dart';
import 'src/midi_player_plugin.dart';
//import 'package:meta/meta.dart';

class Player {
  final int _id;
  bool loaded = false;
  bool closed = false;
  final _lock = Lock();

  bool get ready => loaded && !closed;

  //@protected
  var onCompleteController = StreamController<bool>.broadcast(sync: true);

  Stream<bool> get onComplete => onCompleteController.stream;

  Player() : _id = midiPlayerPlugin.nextId;

  Map<String, dynamic> get _newArguments {
    return <String, dynamic>{paramId: _id};
  }

  Future resume() async {
    var arguments = _newArguments;
    await midiPlayerPlugin.invokeMethod<void>(methodPlay, arguments);
  }

  Future pause() async {
    var arguments = _newArguments;
    await midiPlayerPlugin.invokeMethod<void>(methodPause, arguments);
  }

  Future loadFile(String path) async {
    await _lock.synchronized(() async {
      if (loaded) {
        throw StateError('Already loaded');
      }
      var arguments = _newArguments;
      arguments[paramPath] = path;
      await midiPlayerPlugin.invokeMethod<void>(methodLoadFile, arguments);
      loaded = true;
    });
  }

  Future close() async {
    await _lock.synchronized(() async {
      if (!closed) {
        closed = true;
        var arguments = _newArguments;
        await midiPlayerPlugin.invokeMethod<void>(methodClose, arguments);
      }
    });
  }

  Future seekTo(int millis) async {
    await _lock.synchronized(() async {
      if (ready) {
        var arguments = _newArguments;
        arguments[paramMillis] = millis;
        await midiPlayerPlugin.invokeMethod<void>(methodSeek, arguments);
      }
    });
  }

  Future<int?> getDuration() async {
    return await _lock.synchronized(() async {
      if (ready) {
        var arguments = _newArguments;
        var map = await midiPlayerPlugin.invokeMethodMap(
          methodDuration,
          arguments,
        );
        return (map ?? {})[paramMillis] as int?;
      }
      return null;
    });
  }

  Future<int?> getCurrentPosition() async {
    return await _lock.synchronized(() async {
      if (ready) {
        var arguments = _newArguments;
        var map = await midiPlayerPlugin.invokeMethodMap(
          methodCurrentPosition,
          arguments,
        );
        //int warn;
        //print('map $map');
        return (map ?? {})[paramMillis] as int?;
      }
      return null;
    });
  }

  Future<bool?> isPlaying() async {
    return await _lock.synchronized(() async {
      if (ready) {
        var arguments = _newArguments;
        var map = await midiPlayerPlugin.invokeMethodMap(
          methodPlaying,
          arguments,
        );
        //int warn;
        //print('map $map');
        return (map ?? {})[paramPlaying] as bool?;
      }
      return false;
    });
  }
}

class MidiPlayer {
  //static MethodChannel get _channel => channel;
  static bool _debugModeOn = false;

  /// turn on debug mode if you want to see the SQL query
  /// executed natively
  static Future<dynamic> setDebugModeOn([bool on = true]) async {
    await midiPlayerPlugin.invokeMethod<dynamic>(methodSetDebugModeOn, on);
  }

  static Future<bool> getDebugModeOn() async {
    return _debugModeOn;
  }

  // To use in code when you want to remove it later
  @Deprecated('Dev only')
  static Future devSetDebugModeOn([bool on = true]) {
    _debugModeOn = on;
    return setDebugModeOn(on);
  }

  static Future<String?> get platformVersion =>
      midiPlayerPlugin.invokeMethod<String>('getPlatformVersion');

  Future loadData(List<int> data) async {
    var arguments = _newEmptyArguments;
    arguments['data'] = data;
    await midiPlayerPlugin.invokeMethod<void>(methodLoad, arguments);
  }
}

Future<Player> loadFile(String path) async {
  var player = Player();
  await player.loadFile(path);
  midiPlayerPlugin.players[player._id] = player;
  return player;
}

/// Play a midi file:
Future<void> playFile(String path) async {
  if (Platform.isLinux) {
    await linuxPlayMidiFile(path);
  } else {
    var player = await loadFile(path);
    await player.resume();
    await player.onComplete.first;
    await player.close();
  }
}

Map<String, dynamic> get _newEmptyArguments {
  return <String, dynamic>{};
}

MidiPlayer? _mainPlayer;

MidiPlayer get mainPlayer => _mainPlayer ??= MidiPlayer();

Player get newPlayer => Player();
