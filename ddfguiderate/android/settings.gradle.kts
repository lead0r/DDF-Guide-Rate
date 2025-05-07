pluginManagement {
    // Kotlin-entsprechende Version der Flutter SDK-Pfad-Ermittlung
    val flutterSdkPath: String by lazy {
        val properties = java.util.Properties()
        file("local.properties").inputStream().use { properties.load(it) }
        val flutterSdkPath = properties.getProperty("flutter.sdk") 
            ?: throw GradleException("flutter.sdk not set in local.properties")
        flutterSdkPath
    }
    
    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")
    
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

// Neuer deklarativer Flutter-Plugin-Ansatz
plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
}

rootProject.name = "android"

include(":app")