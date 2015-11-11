package com.thetonymaster.pipesandfilters.sink

import com.thetonymaster.pipesandfilters.PipesAndFiltersDriver
import com.thetonymaster.pipesandfilters.weather._

import akka.actor._
import org.joda.time._

import scala.annotation.tailrec

class Sink() extends Actor {
  def receive = {
    case city: City =>
    println(s"Hello your forecast for ${city.name} will be")
    writeWeather(city.weather)
    println(s"The current temperature is ${city.main.temp} °C, Max and Min will be ${city.main.temp_min} °C and ${city.main.temp_max} °C")
    println(s"With a humidity of ${city.main.humidity} percent")
    println("The forecast for the next few days will be")
    writeForecast(city.forecast)
  }

  def writeWeather(list: List[WeatherJSON]): Unit = {
    @tailrec
    def inner(xs: List[WeatherJSON]): Unit = {
      xs match {
        case x :: tail =>
          println(s"The weather is ${x.main} with ${x.description}")
          inner(tail)
        case Nil =>
      }

    }
    inner(list)
  }

  def writeForecast(list: List[ForecastJson]): Unit = {
    @tailrec
    def inner(xs: List[ForecastJson]): Unit = {
      xs match {
        case x :: tail =>
          val dt = new DateTime(x.dt * 1000)
          val date = dt.toString()
          println(s"The forecast for is $date")
          writeWeather(x.weather)
          println(s"A temperature of ${x.temp.morn} during the morning")
          println(s"A temperature of ${x.temp.day} during the day")
          println(s"A temperature of ${x.temp.eve} durint the eve")
          println(s"Max and Min will be ${x.temp.max} °C and ${x.temp.min} °C")
          println(s"With a wind of ${x.speed} and with ${x.deg}°")
          println(s"With a humidity of ${x.humidity} percent ")
          println("")
          inner(tail)
        case Nil =>
          PipesAndFiltersDriver.completedStep()
      }

    }
    inner(list)
  }
}
