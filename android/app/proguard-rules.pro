# Firebase
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# UCrop (image cropping)
-keep class com.yalantis.ucrop** { *; }
-dontwarn com.yalantis.ucrop**

# Play Core split install classes are only needed for deferred components,
# which this app does not use.
-dontwarn com.google.android.play.core.**

# Keep Flutter Play Store split application class
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
