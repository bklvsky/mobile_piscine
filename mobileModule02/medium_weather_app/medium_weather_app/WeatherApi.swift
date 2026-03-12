import OpenMeteoSdk
import Foundation
import CoreLocation


struct WeatherResponse: Decodable {
  let latitude: Double
  let longitude: Double
  let timezone: String
  let timezone_abbreviation: String
  
  let current: CurrentWeather
  let daily: DailyWeather
  let hourly: HourlyWeather
}

struct CurrentWeather: Decodable {
    let time: Date
    let temperature_2m: Float
    let weather_code: Int
    let wind_speed_10m: Float
}

struct HourlyWeather: Decodable {
    let time: [Date]
    let temperature_2m: [Float]
    let weather_code: [Int]
    let wind_speed_10m: [Float]
}

struct DailyWeather: Decodable {
    let time: [Date]
    let temperature_2m_max: [Float]
    let temperature_2m_min: [Float]
    let weather_code: [Int]
    let wind_speed_10m_max: [Float]
}

func buildWeatherURL(latitude: Double, longitude: Double, timezone: String = "auto") -> URL? {
    var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast")!
    components.queryItems = [
        URLQueryItem(name: "latitude", value: String(latitude)),
        URLQueryItem(name: "longitude", value: String(longitude)),
        URLQueryItem(name: "timezone", value: timezone),
        URLQueryItem(name: "daily", value: "weather_code,temperature_2m_max,wind_speed_10m_max,temperature_2m_min"),
        URLQueryItem(name: "hourly", value: "temperature_2m,weather_code,wind_speed_10m"),
        URLQueryItem(name: "current", value: "temperature_2m,weather_code,wind_speed_10m"),
        URLQueryItem(name: "format", value: "json")
    ]
    return components.url
}

/// Fetches weather data from Open-Meteo for the given coordinates.
func fetchWeather(latitude: Double, longitude: Double) async throws -> WeatherResponse {
    guard let url = buildWeatherURL(latitude: latitude, longitude: longitude) else {
        throw URLError(.badURL)
    }
    
    let (data, _) = try await URLSession.shared.data(from: url)
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .custom { decoder in
        let container = try decoder.singleValueContainer()
        let dateString = try container.decode(String.self)
        
        // Try full datetime first (hourly/current: "2025-01-15T12:00")
        let fullFormatter = DateFormatter()
        fullFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
        if let date = fullFormatter.date(from: dateString) {
            return date
        }
        
        // Try date-only (daily: "2025-01-15")
        let dateOnlyFormatter = DateFormatter()
        dateOnlyFormatter.dateFormat = "yyyy-MM-dd"
        if let date = dateOnlyFormatter.date(from: dateString) {
            return date
        }
        
        throw DecodingError.dataCorruptedError(
            in: container,
            debugDescription: "Cannot parse date: \(dateString)"
        )
    }
    return try decoder.decode(WeatherResponse.self, from: data)
}

/// Reverse geocodes coordinates into a CitySuggestion using Apple's CLGeocoder.
func reverseGeocode(latitude: Double, longitude: Double) async -> CitySuggestion? {
    let geocoder = CLGeocoder()
    let clLocation = CLLocation(latitude: latitude, longitude: longitude)
    
    do {
        let placemarks = try await geocoder.reverseGeocodeLocation(clLocation)
        guard let placemark = placemarks.first else { return nil }
        
        return CitySuggestion(
            id: 0,
            name: placemark.locality ?? placemark.name ?? "Unknown",
            country: placemark.country,
            admin1: placemark.administrativeArea,
            latitude: latitude,
            longitude: longitude
        )
    } catch {
        print("Reverse geocoding error:", error.localizedDescription)
        return nil
    }
}

func weatherDescription(code: Int) -> String {
    switch code {
    case 0:
        return "Clear sky"
    case 1:
        return "Mainly clear"
    case 2:
        return "Partly cloudy"
    case 3:
        return "Overcast"
    case 45:
        return "Fog"
    case 48:
        return "Depositing rime fog"
    case 51:
        return "Light drizzle"
    case 53:
        return "Moderate drizzle"
    case 55:
        return "Dense drizzle"
    case 56:
        return "Light freezing drizzle"
    case 57:
        return "Dense freezing drizzle"
    case 61:
        return "Slight rain"
    case 63:
        return "Moderate rain"
    case 65:
        return "Heavy rain"
    case 66:
        return "Light freezing rain"
    case 67:
        return "Heavy freezing rain"
    case 71:
        return "Slight snow fall"
    case 73:
        return "Moderate snow fall"
    case 75:
        return "Heavy snow fall"
    case 77:
        return "Snow grains"
    case 80:
        return "Slight rain showers"
    case 81:
        return "Moderate rain showers"
    case 82:
        return "Violent rain showers"
    case 85:
        return "Slight snow showers"
    case 86:
        return "Heavy snow showers"
    case 95:
        return "Thunderstorm: Slight or moderate"
    case 96:
        return "Thunderstorm with slight hail"
    case 99:
        return "Thunderstorm with heavy hail"
    default:
        return "Unknown weather condition"
    }
}
