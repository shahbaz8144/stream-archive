# ML Kit text recognition language packs
-keep class com.google.mlkit.vision.text.** { *; }

# jzlib (used by Netty)
-keep class com.jcraft.jzlib.** { *; }

# javax.activation
-keep class com.sun.activation.** { *; }
-dontwarn com.sun.activation.**

# Micrometer metrics
-keep class io.micrometer.** { *; }

# AWT & JavaBeans (used by some data processing libs like Jackson)
-keep class java.awt.** { *; }
-dontwarn java.awt.**
-keep class java.beans.** { *; }
-dontwarn java.beans.**

# Apache Log4j
-keep class org.apache.log4j.** { *; }
-keep class org.apache.logging.log4j.** { *; }
-dontwarn org.apache.**

# SLF4J
-keep class org.slf4j.** { *; }

# Conscrypt
-keep class org.conscrypt.** { *; }

# Jetty
-keep class org.eclipse.jetty.** { *; }

# Reactor & BlockHound
-keep class reactor.blockhound.** { *; }
-keep class reactor.netty.** { *; }

# Netty logging
-keep class io.netty.util.internal.logging.** { *; }

# Prevent R8 from removing them silently
-dontnote **
-dontwarn **
