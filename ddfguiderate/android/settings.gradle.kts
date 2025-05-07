pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
    plugins {
        id("com.android.application") version "8.1.0"
        id("com.android.library") version "8.1.0"
        id("org.jetbrains.kotlin.android") version "1.8.22"
    }
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.name = "ddfguiderate"
include(":app")

// Flutter configuration
val flutterProjectRoot = rootProject.projectDir.parentFile
val pluginsFile = File(flutterProjectRoot, ".flutter-plugins")
if (pluginsFile.exists()) {
    pluginsFile.readLines().forEach { line ->
        if (line.isNotEmpty() && line.contains("=")) {
            val parts = line.split("=", limit = 2)
            if (parts.size == 2) {
                val name = parts[0].trim()
                val path = parts[1].trim()
                if (name.isNotEmpty() && path.isNotEmpty()) {
                    include(":$name")
                    project(":$name").projectDir = File(path)
                }
            }
        }
    }
}

// Flutter SDK path
val localPropertiesFile = File(flutterProjectRoot, "local.properties")
if (localPropertiesFile.exists()) {
    val properties = java.util.Properties()
    localPropertiesFile.inputStream().use { properties.load(it) }
    val flutterSdkPath = properties.getProperty("flutter.sdk")
    if (flutterSdkPath != null) {
        apply(from = "$flutterSdkPath/packages/flutter_tools/gradle/app_plugin_loader.gradle")
    }
}