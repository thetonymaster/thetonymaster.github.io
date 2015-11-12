package com.thetonymaster.fibserver

import com.thetonymaster.common._

import java.io.File
import scala.annotation.tailrec

import akka.actor._
import com.typesafe.config.ConfigFactory


class FibServer extends Actor {
  override def receive: Receive = {
    case req: FibRequest => {
      val res = fib(req.num)
      sender ! Result(req.num, res)
    }
    case _ => println("Received unknown msg ")
  }

  def fib( n : Int) : Int = {
    def fib_tail( n: Int, a:Int, b:Int): Int = n match {
      case 0 => a
      case _ => fib_tail( n-1, b, (a+b)%1000000 )
    }
    return fib_tail( n%1500000, 0, 1)
  }
}

object FibServer {
  def main(args: Array[String]) {
    val configFile = getClass.getClassLoader.getResource("remote_application.conf").getFile
    val config = ConfigFactory.parseFile(new File(configFile))
    val system = ActorSystem("RemoteSystem" , config)
    val remote = system.actorOf(Props[FibServer], name="remote")
    println("remote is ready")
  }
}
