import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")

if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use(keystoreProperties::load)
}

val signingPropertyNames =
    listOf("storeFile", "storePassword", "keyAlias", "keyPassword")
val hasCompleteReleaseSigning =
    keystorePropertiesFile.exists() &&
        signingPropertyNames.all { !keystoreProperties.getProperty(it).isNullOrBlank() }

if (keystorePropertiesFile.exists() && !hasCompleteReleaseSigning) {
    throw GradleException(
        "android/key.properties existe, pero la configuracion de firma esta incompleta.",
    )
}

val allowDebugReleaseSigning =
    providers.environmentVariable("STUDYBOOK_ALLOW_DEBUG_RELEASE_SIGNING").orNull == "true"

android {
    namespace = "com.studybookai.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.studybookai.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (hasCompleteReleaseSigning) {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = when {
                hasCompleteReleaseSigning -> signingConfigs.getByName("release")
                allowDebugReleaseSigning -> signingConfigs.getByName("debug")
                else -> null
            }
        }
    }
}

flutter {
    source = "../.."
}

tasks.configureEach {
    if (name in setOf("assembleRelease", "bundleRelease", "packageRelease")) {
        doFirst {
            if (!hasCompleteReleaseSigning && !allowDebugReleaseSigning) {
                throw GradleException(
                    "Release signing is not configured. Add an ignored android/key.properties " +
                        "or set STUDYBOOK_ALLOW_DEBUG_RELEASE_SIGNING=true for a non-uploadable QA artifact.",
                )
            }
        }
    }
}
