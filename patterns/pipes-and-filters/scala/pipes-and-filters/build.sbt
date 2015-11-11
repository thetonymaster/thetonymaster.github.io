name := """pipes-and-filters"""

version := "1.0"

scalaVersion := "2.11.7"

libraryDependencies ++= Seq(
  "com.typesafe.akka" %% "akka-actor" % "2.3.11",
  "com.typesafe.akka" %% "akka-testkit" % "2.3.11" % "test",
  "org.scalatest" %% "scalatest" % "2.2.4" % "test",
  "org.scalaj" %% "scalaj-http" % "1.1.6",
  "net.liftweb" %% "lift-json" % "2.6.2",
  "joda-time" % "joda-time" % "2.9",
  "org.joda" % "joda-convert" % "1.8")


fork in run := true
