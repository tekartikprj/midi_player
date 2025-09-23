# Recreate project

```
rm -rf android/.gradle
rm -rf android/gradle
rm android/build.gradle
rm android/gradle.properties
rm android/gradlew
rm android/gradlew.bat
rm android/settings.gradle
rm android/settings_aar.gradle
flutter create -t app --project-name midi_player_example --org com.tekartik.midiplayer --platforms android .
```