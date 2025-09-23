# Recreate project

```
rm -rf android/.gradle
rm -rf android/build
rm -rf example
flutter create -t plugin --project-name tekartik_midi_player --platforms android .
rm -rf example
```