pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
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
        val (name, path) = line.split("=")
        include(":$name")
        project(":$name").projectDir = File(path)
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