//
//  ContentView.swift
//  medium_weather_app
//
//  Created by Aleksandra Kachanova on 18/11/2025.
//

import SwiftUI

struct ContentView: View {
    @State private var selection = tabs[0].title
    @State private var weatherLocation: WeatherLocation?
    @State private var errorMessage: String?
    @StateObject private var viewModel = SearchViewModel()
    @StateObject var locationManager = LocationManager()
    @StateObject private var networkMonitor = NetworkMonitor()
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        ZStack(alignment: .top) {
            // Main content: error replaces weather entirely
            if let error = errorMessage {
                VStack {
                    Spacer()
                    Text(error)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding()
                    Spacer()
                }
            } else {
                VStack {
                    TabView(selection: $selection) {
                        ForEach(tabs, id: \.title) { tab in
                            WeatherView(weatherLocation: $weatherLocation, time: tab.title)
                        }
                    }.tabViewStyle(.page(indexDisplayMode: .never))
                }
            }
            if !viewModel.results.isEmpty {
                List(viewModel.results) { city in
                    Button {
                        isSearchFocused = false
                        Task {
                            errorMessage = nil
                            weatherLocation = WeatherLocation(location: city, isLoading: true)
                            do {
                                weatherLocation = try await viewModel.selectCity(city)
                            } catch {
                                weatherLocation = WeatherLocation(location: city)
                                errorMessage = "Failed to load weather: \(error.localizedDescription)"
                            }
                        }
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(city.name)
                                .font(.headline)
                            
                            // Build "Region – Country" line if available
                            let region = city.admin1 ?? ""
                            let country = city.country ?? ""
                            let subtitle = [country, region]
                                .filter { !$0.isEmpty }
                                .joined(separator: " - ")
                            
                            if !subtitle.isEmpty {
                                Text(subtitle)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            CustomTabBar(selection: $selection)
                .background(.thinMaterial)
        }
        .safeAreaInset(edge: .top) {
            SearchBar(
                location: $weatherLocation,
                errorMessage: $errorMessage,
                viewModel: viewModel,
                locationManager: locationManager,
                isSearchFocused: $isSearchFocused
            ).background(Color.yellow)
        }
        // Forward search errors to global error
        .onChange(of: viewModel.errorMessage) { newError in
            if let error = newError {
                errorMessage = error
            }
        }
        .onChange(of: networkMonitor.isConnected) { connected in
            if connected, errorMessage != nil {
                errorMessage = nil
                if let location = weatherLocation?.location {
                    weatherLocation = WeatherLocation(location: location, isLoading: true)
                    Task {
                        do {
                            weatherLocation = try await viewModel.selectCity(location)
                        } catch {
                            errorMessage = "Failed to load weather: \(error.localizedDescription)"
                        }
                    }
                } else {
                    locationManager.requestLocation()
                }
            }
        }
        .ignoresSafeArea(.keyboard)
    }
}

#Preview {
    ContentView()
}
