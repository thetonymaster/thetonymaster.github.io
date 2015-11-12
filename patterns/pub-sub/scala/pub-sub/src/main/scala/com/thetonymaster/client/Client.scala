package com.thetonymaster.client


import com.thetonymaster.completableapp._
import com.thetonymaster.pubsubserver._


import akka.actor._
import akka.event._
import akka.util._

object Client extends CompletableApp(3) {
  val subsA = system.actorOf(Props[SubscriberA], "subscriberA")
  val subsB = system.actorOf(Props[SubscriberB], "subscriberB")
  val subsC = system.actorOf(Props[SubscriberC], "subscriberC")

  val pubsubserver = new PubSubServer

  pubsubserver.subscribe(subsA, Channel("topicA"))
  pubsubserver.subscribe(subsB, Channel("topicB"))
  pubsubserver.subscribe(subsC, Channel("topicA"))

  pubsubserver.publish(Message(Channel("topicA"), "Hello"))
  pubsubserver.publish(Message(Channel("topicB"), "Bye"))

  awaitCompletion
}

class SubscriberA extends Actor {
  def receive = {
    case msg: Message =>
      println(msg.payload + " received from sub a")
      Client.completedStep
  }
}
class SubscriberB extends Actor {
  def receive = {
    case msg: Message =>
      println(msg.payload + " received from sub b")
      Client.completedStep
  }
}
class SubscriberC extends Actor {
  def receive = {
    case msg: Message =>
      println(msg.payload + " received from sub c")
      Client.completedStep
  }
}
