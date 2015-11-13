package com.thetonymaster.competingconsumers

import com.thetonymaster.completableapp._

import akka.actor._
import akka.routing.SmallestMailboxPool

object CompetingConsumers extends CompletableApp(10) {

  def sleep(time: Any): Unit = {
    Thread.sleep(time.asInstanceOf[Int])
  }

  val workItemsProvider = system.actorOf(
                      Props[Worker]
                        .withRouter(SmallestMailboxPool(nrOfInstances = 5)))

  val r = scala.util.Random
  for (itemCount <- 1 to 10) {

    workItemsProvider ! Work(r.nextInt(3000), sleep)
  }

  awaitCompletion
}


case class Work(payload: Any, callback: (Any) => Unit)

class Worker extends Actor {
  def receive = {
    case work: Work =>
      work.callback(work.payload)
      println(s"${self.path.name} Just finished a job")
      CompetingConsumers.completedStep
  }
}
