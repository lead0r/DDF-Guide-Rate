import java.util.Properties
import java.io.FileInputStream
import java.io.File

pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

val flutterSdkPath = Properties().apply {
    FileInputStream(file("local.properties")).use { load(it) }
}.getProperty("flutter.sdk")

if (flutterSdkPath != null) {
    includeBuild(File(flutterSdkPath, "packages/flutter_tools/gradle"))
}

include(":app")
