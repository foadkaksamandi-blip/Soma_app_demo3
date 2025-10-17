# تنظیمات ProGuard برای بیلد Release (فعلاً ساده نگه داشته شده)
# در صورت نیاز بعداً برای BLE یا QR توسعه داده می‌شود.

-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.**
