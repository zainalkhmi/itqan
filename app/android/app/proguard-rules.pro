# Flutter & Dart Proguard Rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# OnnxRuntime Native JNI rules
-keep class ai.onnxruntime.** { *; }
-keep class ai.onnxruntime.internal.** { *; }
-dontwarn ai.onnxruntime.**

# Audio plugins & Hive storage
-keep class com.ryanheise.** { *; }
-keep class com.ryanheise.just_audio.** { *; }
-keep class io.hive.** { *; }

# Avoid breaking JNI native callbacks
-keepclasseswithmembernames class * {
    native <methods>;
}

