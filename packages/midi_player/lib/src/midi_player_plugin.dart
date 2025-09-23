import 'package:flutter/services.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_midi_player/midi_player.dart';

import 'constant.dart';

class MidiPlayerPlugin {
  final Map<int, Player> players = {};
  int _lastId = 0;

  int get nextId {
    return ++_lastId;
  }

  MethodChannel get channel => _channel;
  static const MethodChannel _channel = MethodChannel(pluginName);

  Future<T?> invokeMethod<T>(String method, [dynamic arguments]) =>
      _channel.invokeMethod<T>(method, arguments);

  Future<Map<String, dynamic>?> invokeMethodMap(
    String method, [
    Map<String, dynamic>? arguments,
  ]) async {
    var map = (await _channel.invokeMethod(method, arguments)) as Map?;
    return map?.cast<String, dynamic>();
  }

  MidiPlayerPlugin() {
    _channel.setMethodCallHandler(_handleMethod);
  }

  Future _handleMethod(MethodCall call) async {
    // devPrint("_handleMethod(${call.method})");
    switch (call.method) {
      case methodOnComplete:
        var playerId = (call.arguments as Map)[paramId];
        var player = players[playerId];
        if (player != null) {
          player.onCompleteController.add(true);
        }
        break;
    }
  }
}

MidiPlayerPlugin? _midiPlayerPlugin;

MidiPlayerPlugin get midiPlayerPlugin =>
    _midiPlayerPlugin ??= MidiPlayerPlugin();
