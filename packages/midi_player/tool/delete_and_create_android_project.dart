import 'package:process_run/shell.dart';
import 'package:process_run/stdio.dart';

Future<void> main() async {
  var shell = Shell();
  var androidDir = Directory('android');
  if (androidDir.existsSync()) {
    await androidDir.delete(recursive: true);
  }
  await shell.run(
    'flutter create --platforms android --template plugin --org com.tekartik --project-name tekartik_midi_player .',
  );
}
