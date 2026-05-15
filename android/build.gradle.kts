allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    val projectDrive = project.projectDir.absolutePath.substring(0, 1).lowercase()
    val rootDrive = rootProject.rootDir.absolutePath.substring(0, 1).lowercase()

    if (projectDrive == rootDrive) {
        project.layout.buildDirectory.value(newSubprojectBuildDir)
    } else {
        project.layout.buildDirectory.value(project.layout.projectDirectory.dir("build"))
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
