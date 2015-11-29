package com.thetonymaster.router

import com.thetonymaster.completableapp._

import scala.collection.Map
import akka.actor._

case class Order(id: String, orderType: String, orderItems: Map[String, OrderItem])
{
  val grandTotal: Double = orderItems.values.map(orderItem => orderItem.price).sum

  override def toString(): String =  {
    s"Order($id, $orderType, $orderItems, Totaling $grandTotal)"
  }
}

case class OrderItem(id: String, itemType: String, description: String, price: Double){
  override def toString(): String =  {
    s"OrderItem($id, $itemType, '$description', $price)"
  }

}

case class OrderPlaced(order: Order)

object ContentBasedRouter extends CompletableApp(3) {
  val orderRouter = system.actorOf(Props[OrderRouter], "orderRouter")
  val orderItem1 = OrderItem("1", "A", "A.1 type", 2995)
  val orderItem2 = OrderItem("2", "A", "A.2 type", 6000)
  val orderItem3 = OrderItem("3", "A", "A.3 type", 7985)

  val orderItemsOfTypeA = Map(
        orderItem1.itemType -> orderItem1,
        orderItem2.itemType -> orderItem2,
        orderItem3.itemType -> orderItem3
  )

  orderRouter ! OrderPlaced(Order("123", "TypeA", orderItemsOfTypeA))

  val orderItem4 = OrderItem("1", "B", "B.1 type", 300)
  val orderItem5 = OrderItem("2", "B", "B.2 type", 5087)
  val orderItem6 = OrderItem("3", "B", "B.3 type", 4359)

  val orderItemsOfTypeB = Map(
        orderItem4.itemType -> orderItem4,
        orderItem5.itemType -> orderItem5,
        orderItem6.itemType -> orderItem6
  )

  orderRouter ! OrderPlaced(Order("123", "TypeB", orderItemsOfTypeB))
  awaitCompletion
}

class OrderRouter extends Actor {
  val inventoryA = context.actorOf(Props(classOf[InventorySystem], "InventoryA"), "inventoryA")
  val inventoryB = context.actorOf(Props(classOf[InventorySystem], "InventoryB"), "inventoryB")

  def receive = {
    case orderPlaced: OrderPlaced =>
      orderPlaced.order.orderType match {
        case "TypeA" =>
          inventoryA ! orderPlaced
        case "TypeB" =>
          inventoryB ! orderPlaced
        case _ =>
          println("OrderRouter: received unexpected message")
      }
      ContentBasedRouter.completedStep()
  }
}

class InventorySystem(inventoryName: String) extends Actor {
  def receive = {
    case OrderPlaced(order) =>
      println(s"$inventoryName: handling $order")
      ContentBasedRouter.completedStep()
    case _ =>
      println(s"$inventoryName: unexpected message")
  }
}
