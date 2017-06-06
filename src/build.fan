using build
class Build : build::BuildPod
{
  new make()
  {
    podName = "javaDeploy"
    summary = ""
    srcDirs = [`fan/`]
    depends = ["sys 1.0", "build 1.0"]
  }
}
