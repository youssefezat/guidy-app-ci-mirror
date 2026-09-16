# Flutter Rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Google Play Services & Maps
-keep class com.google.android.gms.maps.** { *; }
-keep interface com.google.android.gms.maps.** { *; }
-keep class com.google.android.gms.common.** { *; }

# Firebase
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception
-keep class com.google.firebase.** { *; }

# Facebook SDK
-keep class com.facebook.** { *; }
-keep class com.facebook.login.** { *; }

# Google Mobile Ads (AdMob)
-keep public class com.google.android.gms.ads.** { public *; }
-keep public class com.google.ads.** { public *; }

# Flutter's embedding engine references Google Play "deferred components"
# (dynamic feature delivery) classes that only exist if the app depends on
# com.google.android.play:core. Guidy ships as one normal APK and doesn't
# use deferred/dynamic feature delivery, so those classes are never on the
# classpath -- R8 (as of recent AGP versions) treats that as a hard error
# by default instead of a warning, which fails minifyRelease. This is
# Flutter's own documented fix for that exact failure, not a Guidy-specific
# workaround: https://github.com/flutter/flutter/issues/119020
-dontwarn com.google.android.play.core.**
