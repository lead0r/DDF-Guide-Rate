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
val plugins = new File(flutterProjectRoot, '.flutter-plugins')
if (plugins.exists()) {
    plugins.eachLine { line ->
        def (name, path) = line.split('=')
        include(":$name")
        project(":$name").projectDir = new File(path)
    }
}

// Flutter SDK path
val localProperties = new File(flutterProjectRoot, "local.properties")
if (localProperties.exists()) {
    Properties properties = new Properties()
    localProperties.withInputStream { properties.load(it) }
    val flutterSdkPath = properties.getProperty('flutter.sdk')
    if (flutterSdkPath != null) {
        apply from: "$flutterSdkPath/packages/flutter_tools/gradle/app_plugin_loader.gradle"
    }
}