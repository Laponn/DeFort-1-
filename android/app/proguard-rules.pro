# ========================================
# DeFort Security - ProGuard / R8 Rules
# ========================================

# Keep Kaspersky SDK classes
-keep class com.kavsdk.** { *; }
-keep class com.kaspersky.** { *; }
-dontwarn com.kavsdk.**
-dontwarn com.kaspersky.**

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep Flutter engine
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# Keep annotations
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-keepattributes Signature

# Keep serializable classes
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Keep enums
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Prevent stripping of Kaspersky SDK interfaces
-keep interface com.kavsdk.** { *; }
-keep interface com.kaspersky.** { *; }
