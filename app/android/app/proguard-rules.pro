# youtubedl-android reads its JSON with Jackson and unzips Python and ffmpeg
# with Commons Compress, both by reflection: R8 must keep the names they look
# for (crash "class … is not a concrete class" otherwise).
-keep class com.yausername.** { *; }
-keep class com.fasterxml.jackson.** { *; }
-keep class org.apache.commons.compress.** { *; }
-keepattributes *Annotation*,Signature,InnerClasses,EnclosingMethod
-dontwarn com.fasterxml.jackson.databind.**
-dontwarn org.apache.commons.compress.**
