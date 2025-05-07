// Top-level build file where you can add configuration options common to all sub-projects/modules.
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // Upgrade auf 7.3.1, weil Flutter bald die Unterstützung für 7.3.0 einstellen wird
        classpath("com.android.tools.build:gradle:7.3.1")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.7.20")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
        
        // Verwenden Sie eine Hardcoded URL anstelle der Projektreferenz
        // Dies vermeidet den Zugriff auf 'android' vor der Definition
        maven {
            url = uri("${rootDir}/../.pub-cache/hosted/pub.dartlang.org/background_fetch-0.7.3/android/libs")
            // Alternativ einen absoluten Pfad verwenden
            // url = uri("/Users/nevial/StudioProjects/DDF-Guide-Rate/ddfguiderate/.pub-cache/hosted/pub.dartlang.org/background_fetch-0.7.3/android/libs")
        }
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}