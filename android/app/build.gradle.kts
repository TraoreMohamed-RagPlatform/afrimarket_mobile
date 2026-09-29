plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.afrimarket.afrimarket_mobile"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    // Nécessaire pour générer le nom de l'app (resValue) par environnement
    buildFeatures {
        resValues = true
    }

    defaultConfig {
        applicationId = "com.afrimarket.afrimarket_mobile"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // ------------------------------------------------------------
    // Environnements : dev / staging / prod
    // Chaque flavor s'installe séparément sur le téléphone.
    // La config Dart correspondante est dans config/<flavor>.json
    // ------------------------------------------------------------
    flavorDimensions += "environment"

    productFlavors {
        create("dev") {
            dimension = "environment"
            applicationIdSuffix = ".dev"
            versionNameSuffix = "-dev"
            resValue("string", "app_name", "AfriMarket Dev")
        }
        create("staging") {
            dimension = "environment"
            applicationIdSuffix = ".staging"
            versionNameSuffix = "-staging"
            resValue("string", "app_name", "AfriMarket Staging")
        }
        create("prod") {
            dimension = "environment"
            resValue("string", "app_name", "AfriMarket")
        }
    }

    buildTypes {
        release {
            // TODO (avant publication Play Store) : signature avec une clé
            // de production stockée hors du dépôt (GitHub Secrets).
            // Signature debug pour l'instant, afin que les builds release fonctionnent.
            signingConfig = signingConfigs.getByName("debug")
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