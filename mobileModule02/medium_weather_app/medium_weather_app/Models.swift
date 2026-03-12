//
//  Models.swift
//  medium_weather_app
//
//  Created by Aleksandra Kachanova on 24/11/2025.
//

//import Foundation

struct GeocodingResponse: Decodable {
    let results: [CitySuggestion]?
}

struct CitySuggestion: Decodable, Identifiable {
    let id: Int
    let name: String
    let country: String?
    let admin1: String? // city's region
    let latitude: Double
    let longitude: Double
}

struct WeatherLocation {
    var location: CitySuggestion?
    var weatherData: WeatherResponse?
    var isLoading: Bool = false
}