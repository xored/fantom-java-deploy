using build

** 
** Works as normal 'BuildPod', but also allows to create normal or subordinate jars
** and install/deploy them into maven. 
** 
class BuildJar : build::BuildPod
{
  private static const Str mavenExe := "mvn"
  
  ** If 'true', build subordinate jar. Look at 'SubordinateJarDist' for details.
  Bool subordinate := false
  
  Str jarName := ""
  Str mainMethod := "" 
  
  Str mvnGroupId := ""
  Str mvnArtifactId := ""
  Str mvnVersion := ""
  
  Str mvnRepositoryUrl := ""
  Str mvnRepositoryId := ""

  Str[] excludeFromJar := [,]
  
  private Void validateJar() {
    if (jarName.isEmpty) throw fatal("Must set jarName")
    if (mainMethod.isEmpty) throw fatal("Must set mainMethod")
  }
  
  @Target { help = "compile pod and build jar" }
  Void jar() {
    validateJar
    compile
    dist := subordinate ? SubordinateJarDist(this) : JarDist(this)
    dist->outFile = `./$jarName`.toFile.normalize

    depNames := depends.map { it[0 ..< (it.index(" ") ?: it.size)] }
    excludeFromJar.each { depNames.remove(it) }
    depNames.remove("sys")
    dist->podNames = [podName].addAll(depNames)
    
    dist->mainMethod = mainMethod
    dist.run
  }
  
  private Void validateMvnInstall() {
    validateJar
    if (mvnGroupId.isEmpty) throw fatal("Must set mvnGroupId")
    if (mvnArtifactId.isEmpty) throw fatal("Must set mvnArtifactId")
    if (mvnVersion.isEmpty) throw fatal("Must set mvnVersion")
  }
  
  @Target { help = "compile pod, build jar and install it into local maven repo" }
  Void mvnInstall() {
    validateMvnInstall
    jar
    Str[] paramList := [
      "mvn",
      "install:install-file", 
      "-Dfile=$jarName", 
      "-DgroupId=$mvnGroupId",
      "-DartifactId=$mvnArtifactId",
      "-Dversion=$mvnVersion",
      "-Dpackaging=jar",
      "-DgeneratePom=true"
    ]
    execCli(paramList)
  }

  private Void validateMvnDeploy() {
    validateMvnInstall
    if (mvnRepositoryUrl.isEmpty) throw fatal("Must set mvnRepositoryUrl")
    if (mvnRepositoryId.isEmpty) throw fatal("Must set mvnRepositoryId")
  }
  
  @Target { help = "compile pod, build jar and deploy it into maven repo" }
  Void mvnDeploy() {
    jar
    Str[] paramList := [
      "mvn",
      "deploy:deploy-file", 
      "-Durl=$mvnRepositoryUrl",
      "-DrepositoryId=$mvnRepositoryId",
      "-Dfile=$jarName", 
      "-DgroupId=$mvnGroupId",
      "-DartifactId=$mvnArtifactId",
      "-Dversion=$mvnVersion",
      "-Dpackaging=jar",
      "-DgeneratePom=true"
    ]
    execCli(paramList)
  }
  
  private Void execCli(Str[] paramList) {
    if ("win32" == Env.cur.os) {
      // "mvn" is a bat script on Windows
      paramList.insertAll(0, [ "cmd.exe", "/c" ])
    }
    Exec(this, paramList).run
  }
}

