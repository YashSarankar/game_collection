# Flutter Proguard Rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
# Avoid errors from removed dependencies
-dontwarn com.google.android.gms.**
-dontwarn com.google.ads.**
-dontwarn com.google.android.ads.**
-dontwarn com.google.android.play.core.**
-dontwarn com.google.android.gms.internal.**



# Lottie Proguard Rules
-keep class com.airbnb.lottie.** { *; }
