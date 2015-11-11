package com.thetonymaster.pipesandfilters.weatherendpoint

import com.thetonymaster.pipesandfilters.weather._

import scala.annotation.tailrec

import akka.actor._
import net.liftweb.json._

class WeatherEndpoint(nextFilter: ActorRef) extends Actor {
  implicit val formats = DefaultFormats

  def receive = {
    case weather: String =>
      val json = parse(weather)
      val value = json.extract[WeatherList]
      getCities(value.list)

  }

  def getCities(list: List[CityJSON]): Unit = {
    @tailrec
    def inner(xs: List[CityJSON]): Unit = {
      xs match {
        case x :: tail =>
          nextFilter ! x
          inner(tail)
        case Nil =>
      }

    }
    inner(list)
  }

}
