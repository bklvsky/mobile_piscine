//
//  Tabs.swift
//  medium_weather_app
//
//  Created by Aleksandra Kachanova on 18/11/2025.
//

import SwiftUI


let tabs: [(title: String, systemImage: String)] = [
    ("Currently", "cloud.sun"),
    ("Today", "calendar"),
    ("Weekly", "calendar.badge.clock")
]


struct WeatherView: View {
    @Binding var weatherLocation: WeatherLocation?
    let time: String

    var body: some View {
        VStack {
            if let wl = weatherLocation {
                // Loading state
                if wl.isLoading {
                    if let city = wl.location {
                        Text(city.name).font(.title)
                    }
                    ProgressView()
                        .padding(10)
                }
                // Loaded state: show city + weather data
                else {
                    if let city = wl.location {
                        Text(city.name).font(.title)
                        let region = city.admin1 ?? ""
                        let country = city.country ?? ""
                        let subtitle = [region, country]
                            .filter { !$0.isEmpty }
                            .joined(separator: ", ")
                        if !subtitle.isEmpty {
                            Text(subtitle)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    if let weather = wl.weatherData {
                        switch time {
                        case "Currently":
                            CurrentlyView(weather: weather)
                        case "Today":
                            TodayView(weather: weather)
                        case "Weekly":
                            WeeklyView(weather: weather)
                        default:
                            EmptyView()
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Currently Tab

struct CurrentlyView: View {
    let weather: WeatherResponse

    var body: some View {
        VStack(spacing: 12) {
            Text("\(weather.current.temperature_2m, specifier: "%.1f")°C")
                .font(.system(size: 48, weight: .thin))
            Text(weatherDescription(code: weather.current.weather_code))
                .font(.title3)
            HStack {
                Image(systemName: "wind")
                Text("\(weather.current.wind_speed_10m, specifier: "%.1f") km/h")
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
        .padding()
    }
}

// MARK: - Today Tab (hourly)

struct TodayView: View {
    let weather: WeatherResponse

    private struct HourlyEntry {
        let timeString: String
        let temperature: Float
        let weatherCode: Int
        let windSpeed: Float
    }

    var body: some View {
        let entries = todayHourlyEntries()

        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(entries.indices, id: \.self) { i in
                    HStack {
                        Text(entries[i].timeString)
                            .frame(width: 55, alignment: .leading)
                            .font(.subheadline.monospacedDigit())
                        Text(weatherDescription(code: entries[i].weatherCode))
                            .font(.subheadline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .lineLimit(1)
                        Text("\(entries[i].temperature, specifier: "%.1f")°")
                            .font(.subheadline.monospacedDigit())
                            .frame(width: 55, alignment: .trailing)
                        HStack(spacing: 2) {
                            Image(systemName: "wind")
                                .font(.caption2)
                            Text("\(entries[i].windSpeed, specifier: "%.0f") km/h")
                                .font(.caption.monospacedDigit())
                        }
                        .frame(width: 45, alignment: .trailing)
                        .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 6)
                    Divider()
                }
            }
        }
    }

    private func todayHourlyEntries() -> [HourlyEntry] {
        var calendar = Calendar.current
        if let tz = TimeZone(identifier: weather.timezone) {
            calendar.timeZone = tz
        }
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!

        let hourFormatter = DateFormatter()
        hourFormatter.dateFormat = "HH:mm"
        hourFormatter.timeZone = calendar.timeZone

        var entries: [HourlyEntry] = []
        for i in 0..<weather.hourly.time.count {
            let date = weather.hourly.time[i]
            if date >= today && date < tomorrow {
                entries.append(HourlyEntry(
                    timeString: hourFormatter.string(from: date),
                    temperature: weather.hourly.temperature_2m[i],
                    weatherCode: weather.hourly.weather_code[i],
                    windSpeed: weather.hourly.wind_speed_10m[i]
                ))
            }
        }
        return entries
    }
}

// MARK: - Weekly Tab (daily)

struct WeeklyView: View {
    let weather: WeatherResponse

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(0..<weather.daily.time.count, id: \.self) { i in
                    HStack {
                        Text(dayString(from: weather.daily.time[i]))
                            .font(.subheadline)
                            .frame(width: 85, alignment: .leading)
                        Text(weatherDescription(code: weather.daily.weather_code[i]))
                            .font(.subheadline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .lineLimit(1)
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(weather.daily.temperature_2m_max[i], specifier: "%.0f")°")
                                .font(.subheadline.monospacedDigit())
                            Text("\(weather.daily.temperature_2m_min[i], specifier: "%.0f")°")
                                .font(.caption.monospacedDigit())
                                .foregroundColor(.secondary)
                        }
                        .frame(width: 40)
                        HStack(spacing: 2) {
                            Image(systemName: "wind")
                                .font(.caption2)
                            Text("\(weather.daily.wind_speed_10m_max[i], specifier: "%.0f") km/h")
                                .font(.caption.monospacedDigit())
                        }
                        .frame(width: 45, alignment: .trailing)
                        .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    Divider()
                }
            }
        }
    }

    private func dayString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        return formatter.string(from: date)
    }
}
