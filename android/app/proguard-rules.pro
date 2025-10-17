# قوانین ساده برای بیلد Release (الان minify/shrink خاموش است)
# نگه‌داشتن کلاس‌های Flutter/Plugins تا در آینده اگر فعال شد، مشکل نگیریم
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.**
