package com.thetonymaster.pubsubserver


import akka.actor._
import akka.event._
import akka.util._

case class Channel(name: String)
case class Message(channel: Channel, payload: Any)


class PubSubServer extends EventBus with SubchannelClassification {
  type Classifier = Channel
  type Event = Message
  type Subscriber = ActorRef

  protected def classify(event: Event): Classifier = {
    event.channel
  }

  protected def publish(event: Event, subscriber: Subscriber): Unit = {
    subscriber ! event
  }

  protected def subclassification = new Subclassification[Classifier] {
    def isEqual(
        subscribedToClassifier: Classifier,
        eventClassifier: Classifier): Boolean = {

      subscribedToClassifier.equals(eventClassifier)
    }

    def isSubclass(
        subscribedToClassifier: Classifier,
        eventClassifier: Classifier): Boolean = {

      subscribedToClassifier.name.startsWith(eventClassifier.name)
    }
  }
}
