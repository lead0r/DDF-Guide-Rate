pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

rootProject.name = "android"

include(":app")
include(":background_fetch")

// Stellen Sie sicher, dass background_fetch richtig eingebunden ist
// Dies weist auf den richtigen Pfad für das background_fetch-Modul hin
project(":background_fetch").projectDir = file("../build/background_fetch/android")