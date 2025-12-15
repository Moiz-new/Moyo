# ============================================
# Google Play Core - Fix Missing Classes
# ============================================
-keep class com.google.android.play.core.** { *; }
-keep class com.google.android.play.core.splitcompat.** { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }
-dontwarn com.google.android.play.core.**

# ============================================
# Keep Razorpay classes and suppress related warnings
# ============================================
-keep class com.razorpay.** { *; }
-dontwarn com.razorpay.**

# ============================================
# Keep Google Pay (GPay) related classes and suppress warnings
# ============================================
-keep class com.google.android.apps.nbu.paisa.inapp.client.api.** { *; }
-dontwarn com.google.android.apps.nbu.paisa.inapp.client.api.**

# ============================================
# Keep annotation attributes (required for runtime)
# ============================================
-keepattributes *Annotation*, RuntimeVisibleAnnotations, Signature, InnerClasses, EnclosingMethod

# ============================================
# Suppress annotation warnings
# ============================================
-dontwarn proguard.annotation.Keep
-dontwarn proguard.annotation.KeepClassMembers

# ============================================
# Parcelable and Serializable support
# ============================================
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

-keepnames class * implements java.io.Serializable
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    !static !transient <fields>;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# ============================================
# Prevent ProGuard from stripping interface information
# ============================================
-keep interface * extends *

# ============================================
# Kotlin-specific rules
# ============================================
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }
-dontnote kotlin.internal.**
-dontnote kotlin.reflect.jvm.**
-dontnote kotlin.coroutines.**

-keepclassmembers class * {
    @proguard.annotation.Keep *;
}
-keepclassmembers class * {
    @proguard.annotation.KeepClassMembers *;
}

# ============================================
# Suppress verbose warnings in build output
# ============================================
-dontwarn kotlinx.coroutines.**
-dontwarn kotlin.Metadata

# ============================================
# Flutter-specific rules - CRITICAL FOR YOUR ISSUE
# ============================================
-keep class io.flutter.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugins.** { *; }

# ============================================
# CRITICAL: Keep ALL methods that update state
# ============================================
-keepclassmembers class * {
    public void set*(...);
    public *** get*();
    public void update*(...);
    public void notifyListeners();
}

# ============================================
# File Picker Plugin - Fix warnings
# ============================================
-dontwarn com.mr.flutter.plugin.filepicker.**
-keep class com.mr.flutter.plugin.filepicker.** { *; }

# ============================================
# CRITICAL: Disable aggressive optimizations for release
# ============================================
-dontoptimize
-dontobfuscate

# ============================================
# Keep line numbers for debugging
# ============================================
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile