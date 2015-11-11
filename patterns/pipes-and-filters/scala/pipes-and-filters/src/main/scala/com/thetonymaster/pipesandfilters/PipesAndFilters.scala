package com.thetonymaster.pipesandfilters

import com.thetonymaster.CompletableApp
import com.thetonymaster.pipesandfilters.weatherendpoint.WeatherEndpoint
import com.thetonymaster.pipesandfilters.weatherforecast.WeatherForecast
import com.thetonymaster.pipesandfilters.sink.Sink

import akka.actor._
import scalaj.http._

object PipesAndFiltersDriver extends CompletableApp(10) {

    val filter3 = system.actorOf(Props[Sink], "sink")
    val filter2 = system.actorOf(Props(classOf[WeatherForecast], filter3), "weatherForecast")
    val filter1 = system.actorOf(Props(classOf[WeatherEndpoint], filter2), "weatherEndpoint")
    val weatherURL: String = "http://api.openweathermap.org/data/2.5/group?id=3979844,4005539,3530597,4005270&units=metric&appid=5a917cc621913d534c113dbae4b5e5d9"

    val request: HttpRequest = Http(weatherURL)
    for(_ <- 0 until 10){
      val response = request.asString
      filter1 ! response.body
      Thread.sleep(1000)
    }
     awaitCompletion
    println("PipesAndFilters: is completed.")

}
