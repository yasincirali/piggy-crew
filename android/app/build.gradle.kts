import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Yükleme anahtarı key.properties'ten (repoda yok, .gitignore'da; CI
// secret'lardan yazar: android-release.yml). Sandık'taki düzenin aynısı.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.sandik.harcliklarim"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // iOS bundle id ile aynı; Play'de bir kez yayınlanınca değişmez.
        applicationId = "com.sandik.harcliklarim"
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
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Debug anahtarına sessizce düşmez (şablonun varsayılanıydı):
            // herkesin bildiği anahtarla imzalı bir AAB Play'e gitmesin.
            // key.properties yoksa aşağıdaki görev kapısı release paketini
            // durdurur; debug build etkilenmez.
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

// Release imzalama kapısı: görev koşarken denetler, yapılandırma okunurken
// değil (yapılandırmada atılan hata `assembleDebug`'ı da kırardı).
tasks.matching { it.name.contains("Release") && (it.name.startsWith("package") || it.name.startsWith("sign")) }
    .configureEach {
        doFirst {
            if (!keystorePropertiesFile.exists()) {
                throw GradleException(
                    "android/key.properties bulunamadı: release build debug " +
                        "anahtarıyla imzalanmaz. Keystore'u kur ya da debug build al.",
                )
            }
        }
    }
