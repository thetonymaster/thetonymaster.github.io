package com.thetonymaster.splitter

import com.thetonymaster.completableapp._

import akka.actor._

case class Order(id: Int, items: Array[OrderItem])
case class OrderItem(id: String, itemType: String, description: String, price: Int)

case class InventoryRequest(id: Int, items: Array[InventoryItems])
case class InventoryItems(id: Int, number: Int)

case class Payment(id: String, paymentType: String, amount: Int)

case class CompleteOrder(order: Order, request: InventoryRequest, payment: Payment)

object Splitter extends CompletableApp(4) {
  val orderRouter = system.actorOf(Props[OrderRouter], "orderRouter")

  val orderItems = Array(
                    OrderItem("LMANS", "Stuff", "It goes beep when there's stuff", 1000),
                    OrderItem("L23KNS", "Non euclidean stuff", "no description possible", 3000)
                    )
  val order = Order(1234, orderItems)

  val inventoryItems = Array(
                      InventoryItems(123, 1),
                      InventoryItems(124, 1)
                      )

  val inventoryRequest = InventoryRequest(1298, inventoryItems)

  val payment = Payment("9817CA", "Credit Card", 3000)

  val completeOrder = CompleteOrder(order, inventoryRequest, payment)

   orderRouter ! completeOrder

  awaitCompletion
  println("Splitter has completed")
}

class OrderRouter extends Actor {
  val orderProcessor = context.actorOf(Props[OrderProcessor], "orderProcessor")
  val inventoryProcessor = context.actorOf(Props[InventoryProcessor], "inventoryProcessor")
  val paymentProcessor = context.actorOf(Props[PaymentProcessor], "paymentProcessor")

  def receive = {
    case order: CompleteOrder =>
      orderProcessor ! order.order
      inventoryProcessor ! order.request
      paymentProcessor ! order.payment
      Splitter.completedStep()
  }
}

class OrderProcessor extends Actor {
  val r = scala.util.Random


  def receive = {
    case order: Order =>
      println(s"OrderProcessor: processing $order")
      r.nextInt(3000)
      Thread.sleep(r.nextInt(3000))
      Splitter.completedStep()
    case _ =>
      println("OrderProcessor: unexpected")
  }
}

class InventoryProcessor extends Actor {
  val r = scala.util.Random

  def receive = {
    case request: InventoryRequest =>
      println(s"InventoryProcessor: processing $request")
      r.nextInt(3000)
      Thread.sleep(r.nextInt(3000))
      Splitter.completedStep()
    case _ =>
      println("InventoryProcessor: unexpected")
  }
}

class PaymentProcessor extends Actor {
  val r = scala.util.Random

  def receive = {
    case payment: Payment =>
      println(s"PaymentProcessor: processing $payment")
      r.nextInt(3000)
      Thread.sleep(r.nextInt(3000))
      Splitter.completedStep()
    case _ =>
      println("PaymentProcessor: unexpected")
  }
}
