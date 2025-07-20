# Keep flutter_local_notifications classes
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class ** implements com.dexterous.flutterlocalnotifications.** { *; }

# Keep notification receiver
-keep class * extends android.content.BroadcastReceiver
-keep class com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver { *; }
-keep class com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver { *; }

# Keep generic type information for Gson (used by flutter_local_notifications)
-keepattributes Signature
-keepattributes *Annotation*

# Keep gson types
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# Keep generic types for reflection
-keepattributes *Annotation*,Signature,InnerClasses,EnclosingMethod

# Prevent obfuscation of generic types
-keep,allowshrinking,allowoptimization class * extends java.util.Collection
-keep,allowshrinking,allowoptimization class * extends java.util.Map
