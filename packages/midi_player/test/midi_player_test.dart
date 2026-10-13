import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tekartik_midi_player/midi_player.dart';
import 'package:tekartik_midi_player/src/constant.dart';
import 'package:tekartik_midi_player/src/midi_player_plugin.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const channel = MethodChannel(pluginName);

  late List<MethodCall> calls;
  late Map<String, Object?> results;

  setUp(() {
    calls = [];
    results = {};
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return results[call.method];
    });
  });
  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
  });

  /// The id sent by the last loadFile call.
  int lastLoadedId() =>
      (calls.lastWhere((call) => call.method == methodLoadFile).arguments
              as Map)[paramId]
          as int;

  /// Simulate the native side notifying the end of a player.
  Future<void> nativeOnComplete(int id) async {
    await messenger.handlePlatformMessage(
      pluginName,
      const StandardMethodCodec().encodeMethodCall(
        MethodCall(methodOnComplete, {paramId: id}),
      ),
      (_) {},
    );
  }

  group('midi_player', () {
    test('Player().loadFile receives onComplete', () async {
      var player = Player();
      await player.loadFile('test.mid');
      var completed = player.onComplete.first;
      await nativeOnComplete(lastLoadedId());
      expect(await completed.timeout(const Duration(seconds: 2)), isTrue);
      await player.close();
    });

    test('newPlayer.loadFile receives onComplete', () async {
      var player = newPlayer;
      await player.loadFile('test.mid');
      var completed = player.onComplete.first;
      await nativeOnComplete(lastLoadedId());
      expect(await completed.timeout(const Duration(seconds: 2)), isTrue);
      await player.close();
    });

    test('close unregisters and closes the controller', () async {
      var player = await loadFile('test.mid');
      expect(midiPlayerPlugin.players.containsValue(player), isTrue);
      await player.close();
      expect(midiPlayerPlugin.players.containsValue(player), isFalse);
      expect(player.onCompleteController.isClosed, isTrue);
      expect(calls.last.method, methodClose);
    });

    test('setDebugModeOn', () async {
      await MidiPlayer.setDebugModeOn();
      expect(await MidiPlayer.getDebugModeOn(), isTrue);
      expect(calls.last.method, methodSetDebugModeOn);
      expect(calls.last.arguments, isTrue);
      await MidiPlayer.setDebugModeOn(false);
      expect(await MidiPlayer.getDebugModeOn(), isFalse);
    });

    test('not ready values', () async {
      var player = Player();
      expect(await player.getDuration(), isNull);
      expect(await player.getCurrentPosition(), isNull);
      expect(await player.isPlaying(), isFalse);
      expect(calls, isEmpty);
    });

    test('ready values', () async {
      results[methodDuration] = {paramMillis: 1234};
      results[methodCurrentPosition] = {paramMillis: 12};
      results[methodPlaying] = {paramPlaying: true};
      var player = await loadFile('test.mid');
      expect(await player.getDuration(), 1234);
      expect(await player.getCurrentPosition(), 12);
      expect(await player.isPlaying(), isTrue);
      await player.close();
      expect(await player.getDuration(), isNull);
      expect(await player.isPlaying(), isFalse);
    });
  });
}
