import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val releaseSigningProperties = Properties().apply {
    val propertiesFile = rootProject.file("key.properties")
    if (propertiesFile.exists()) {
        propertiesFile.inputStream().use(::load)
    }
}

val releaseSigningValues = mapOf(
    "storeFile" to (releaseSigningProperties.getProperty("storeFile") ?: System.getenv("ANDROID_KEYSTORE_PATH")),
    "storePassword" to (releaseSigningProperties.getProperty("storePassword") ?: System.getenv("ANDROID_KEYSTORE_PASSWORD")),
    "keyAlias" to (releaseSigningProperties.getProperty("keyAlias") ?: System.getenv("ANDROID_KEY_ALIAS")),
    "keyPassword" to (releaseSigningProperties.getProperty("keyPassword") ?: System.getenv("ANDROID_KEY_PASSWORD")),
)
val releaseTasksRequested = gradle.startParameter.taskNames.any {
    it.contains("release", ignoreCase = true)
}

if (releaseTasksRequested && releaseSigningValues.values.any { it.isNullOrBlank() }) {
    throw GradleException(
        "Release signing is not configured. Set android/key.properties or the ANDROID_KEYSTORE_* environment variables.",
    )
}

android {
    namespace = "com.ohmae.app.ohmae_mobile"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.ohmae.app.ohmae_mobile"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            releaseSigningValues["storeFile"]?.let { storeFile = rootProject.file(it) }
            releaseSigningValues["storePassword"]?.let { storePassword = it }
            releaseSigningValues["keyAlias"]?.let { keyAlias = it }
            releaseSigningValues["keyPassword"]?.let { keyPassword = it }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
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
