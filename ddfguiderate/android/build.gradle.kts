buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.android.tools.build:gradle:7.3.0")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.7.20")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
        
        // Verwenden Sie einen festen Pfad statt der Projektreferenz
        // Dies vermeidet den Fehler mit der 'android'-Eigenschaft
        maven(url = "file://${rootProject.projectDir}/../.pub-cache/git/flutter_background_fetch-ff9dbf2a0f07a85ce04a8af25407e590e9e23d80/android/libs")
        // Alternativ können Sie auch einen lokalen Pfad verwenden, wenn Sie wissen, wo das Plugin installiert ist
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    // Nur die App evaluieren, nicht background_fetch
    if (project.name != "background_fetch") {
        project.evaluationDependsOn(":app")
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}