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
      // Registered to receive onComplete
      midiPlayerPlugin.players[_id] = this;
    });
  }

  Future close() async {
    await _lock.synchronized(() async {
      if (!closed) {
        closed = true;
        try {
          var arguments = _newArguments;
          await midiPlayerPlugin.invokeMethod<void>(methodClose, arguments);
        } finally {
          midiPlayerPlugin.players.remove(_id);
          await onCompleteController.close();
        }
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

  /// Read [key] of the [method] result, [notReady] if not loaded or closed.
  Future<T?> _invokeWhenReady<T>(String method, String key, {T? notReady}) {
    return _lock.synchronized(() async {
      if (ready) {
        var arguments = _newArguments;
        var map = await midiPlayerPlugin.invokeMethodMap(method, arguments);
        return (map ?? {})[key] as T?;
      }
      return notReady;
    });
  }

  Future<int?> getDuration() =>
      _invokeWhenReady<int>(methodDuration, paramMillis);

  Future<int?> getCurrentPosition() =>
      _invokeWhenReady<int>(methodCurrentPosition, paramMillis);

  Future<bool?> isPlaying() =>
      _invokeWhenReady<bool>(methodPlaying, paramPlaying, notReady: false);
}

class MidiPlayer {
  //static MethodChannel get _channel => channel;
  static bool _debugModeOn = false;

  /// turn on debug mode if you want to see the SQL query
  /// executed natively
  static Future<dynamic> setDebugModeOn([bool on = true]) async {
    _debugModeOn = on;
    await midiPlayerPlugin.invokeMethod<dynamic>(methodSetDebugModeOn, on);
  }

  static Future<bool> getDebugModeOn() async {
    return _debugModeOn;
  }

  // To use in code when you want to remove it later
  @Deprecated('Dev only')
  static Future devSetDebugModeOn([bool on = true]) {
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
