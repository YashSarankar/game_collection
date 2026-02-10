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

# AdMob Proguard Rules (Safeguard)
-keep class com.google.android.gms.ads.** { *; }
-keep class com.google.ads.** { *; }



# Lottie Proguard Rules
-keep class com.airbnb.lottie.** { *; }
