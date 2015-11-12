package com.thetonymaster.client

import com.thetonymaster.common._

import java.io.File

import akka.actor.{Props, Actor, ActorSystem}
import com.typesafe.config.ConfigFactory

class Client extends Actor{
  @throws[Exception](classOf[Exception])
  override def preStart(): Unit = {

    val remoteActor = context.actorSelection("akka.tcp://RemoteSystem@127.0.0.1:5150/user/remote")
    println("That 's remote:" + remoteActor)
    remoteActor ! FibRequest(1)
  }
  override def receive: Receive = {

    case result :Result => {
      println("fibbonacci for " + result.num.toString + " is " + result.res.toString)
    }
  }
}



object Client {

  def main(args: Array[String]) {

    val configFile = getClass.getClassLoader.getResource("local_application.conf").getFile
    val config = ConfigFactory.parseFile(new File(configFile))
    val system = ActorSystem("ClientSystem",config)
    val client = system.actorOf(Props[Client], name="local")
  }


}
