# OkHttp3 - required by ucrop (image_cropper)
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }

# uCrop
-dontwarn com.yalantis.ucrop.**
-keep class com.yalantis.ucrop.** { *; }
-keep interface com.yalantis.ucrop.** { *; }