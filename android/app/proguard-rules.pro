# Flutter ProGuard rules
-keep class com.umkm.mobilepos.** { *; }
-keep class io.flutter.** { *; }

# Play Core (deferred components)
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# CameraX - required by mobile_scanner in release builds
-keep class androidx.camera.** { *; }
-dontwarn androidx.camera.**

# MLKit barcode scanning - plugin's consumer rules use single * which misses subpackages
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**
