# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }

# Play Core (required by Flutter)
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# TFLite
-keep class org.tensorflow.** { *; }
-dontwarn org.tensorflow.**

# Kotlin
-keep class kotlin.** { *; }
-keep class kotlinx.** { *; }
-dontwarn kotlin.**

# Keep native methods
-keepclassmembers class * {
    native <methods>;
}

# Prevent stripping of annotations
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes Exceptions

# Google Sign-In
-keep class com.google.android.gms.auth.** { *; }

# SQLite
-keep class net.sqlcipher.** { *; }
-dontwarn net.sqlcipher.**
