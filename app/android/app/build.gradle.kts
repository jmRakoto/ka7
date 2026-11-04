import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "mg.rakoto.ka7"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "mg.rakoto.ka7"
        // youtubedl-android needs Android 7.
        minSdk = maxOf(24, flutter.minSdkVersion)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // youtubedl-android runs Python and ffmpeg from native libraries: they must
    // be extracted on install.
    packaging {
        jniLibs {
            useLegacyPackaging = true
            // Our copy, fixed for 16 KB pages (tool/android/fix_ffmpeg_16k.sh),
            // replaces the one from youtubedl-android.
            pickFirsts += "**/libffmpeg.zip.so"
        }
    }

    // Release key, kept outside the project: ~/.config/ka7/key.properties
    // (KA7_KEY_PROPERTIES overrides the path, e.g. in CI), see ka7/CLAUDE.md.
    // Without it, release builds fall back to the debug key.
    val keyProperties = Properties().apply {
        val path = System.getenv("KA7_KEY_PROPERTIES")
            ?: "${System.getProperty("user.home")}/.config/ka7/key.properties"
        val file = File(path)
        if (file.exists()) file.inputStream().use { load(it) }
    }
    signingConfigs {
        if (keyProperties.isNotEmpty()) {
            create("release") {
                storeFile = file(keyProperties.getProperty("storeFile"))
                storePassword = keyProperties.getProperty("storePassword")
                keyAlias = keyProperties.getProperty("keyAlias")
                keyPassword = keyProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.findByName("release")
                ?: signingConfigs.getByName("debug")
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    // yt-dlp, Python and ffmpeg embedded (Unlicense / LGPL builds).
    val youtubedlAndroid = "0.18.1"
    implementation("io.github.junkfood02.youtubedl-android:library:$youtubedlAndroid")
    implementation("io.github.junkfood02.youtubedl-android:ffmpeg:$youtubedlAndroid")
    // Writing into a folder the user picked (SD card included).
    implementation("androidx.documentfile:documentfile:1.0.1")
}
