import org.openurp.parent.Dependencies._
import org.openurp.parent.Settings._

ThisBuild / organization := "org.openurp.edu.teaching"
ThisBuild / version := "0.0.7"

ThisBuild / scmInfo := Some(
  ScmInfo(
    url("https://github.com/openurp/edu-teaching"),
    "scm:git@github.com:openurp/edu-teaching.git"
  )
)

ThisBuild / developers := List(
  Developer(
    id = "chaostone",
    name = "Tihua Duan",
    email = "duantihua@gmail.com",
    url = url("http://github.com/duantihua")
  )
)

ThisBuild / description := "OpenURP Edu Teaching"
ThisBuild / homepage := Some(url("http://openurp.github.io/edu-teaching/index.html"))

val apiVer = "0.41.14"
val starterVer = "0.3.51"
val baseVer = "0.4.46"
val eduCoreVer = "0.3.7"
val openurp_edu_api = "org.openurp.edu" % "openurp-edu-api" % apiVer
val openurp_stater_web = "org.openurp.starter" % "openurp-starter-web" % starterVer
val openurp_base_tag = "org.openurp.base" % "openurp-base-tag" % baseVer
val openurp_edu_core = "org.openurp.edu" % "openurp-edu-core" % eduCoreVer

lazy val root = (project in file("."))
  .enablePlugins(WarPlugin, TomcatPlugin)
  .settings(
    name := "openurp-edu-teaching-webapp",
    common,
    libraryDependencies ++= Seq(openurp_stater_web, openurp_edu_core),
    libraryDependencies ++= Seq(openurp_edu_api, beangle_ems_app, openurp_base_tag)
  )
