import com.android.build.gradle.BaseExtension

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
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    afterEvaluate {
        if (project.extensions.findByName("android") != null) {
            val android = project.extensions.getByName("android") as BaseExtension
            
            // 1. Injeta o Namespace se estiver faltando
            if (android.namespace == null) {
                android.namespace = "com.salvefinancas.${project.name.replace("-", "_")}"
            }

            // 2. SOLUÇÃO PARA O ERRO DE MANIFESTO:
            // Este bloco procura o atributo 'package' no XML e o remove em tempo de execução
            // para que o Gradle não interrompa o build.
            project.tasks.matching { 
                it.name.contains("process") && it.name.contains("Manifest") 
            }.configureEach {
                doFirst {
                    val manifestFile = project.file("src/main/AndroidManifest.xml")
                    if (manifestFile.exists()) {
                        val content = manifestFile.readText()
                        if (content.contains("package=")) {
                            val updatedContent = content.replace(Regex("""package="[^"]*""""), "")
                            manifestFile.writeText(updatedContent)
                        }
                    }
                }
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}