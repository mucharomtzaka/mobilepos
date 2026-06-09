# Flutter ProGuard rules
-keep class com.umkm.mobilepos.** { *; }
-keep class io.flutter.** { *; }

# Play Core (deferred components)
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }
