//
//  Bars.swift
//  medium_weather_app
//
//  Created by Aleksandra Kachanova on 18/11/2025.
//


import SwiftUI
import CoreLocation

struct CustomTabBar: View {
    @Binding var selection: String

    var body: some View {
        HStack {
            Spacer()
            ForEach(tabs, id: \.title) { tab in
                Button {
                    selection = tab.title
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.systemImage)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(tab.title == selection ? Color.blue : Color.gray)
                        Text(tab.title)
                            .lineLimit(1)
                            .foregroundStyle(tab.title == selection ? Color.blue : Color.gray)
                    }
                }
                Spacer()
            }
        }
        .frame(maxWidth: .infinity)
        .padding(15)
    }
}

struct SearchBar: View {
    @Binding var location: WeatherLocation?
    @Binding var errorMessage: String?
    @ObservedObject var viewModel: SearchViewModel
    @ObservedObject var locationManager: LocationManager
    var isSearchFocused: FocusState<Bool>.Binding

    private func selectFirstResult() async {
        guard !viewModel.results.isEmpty else { return }
        let city = viewModel.results[0]
        errorMessage = nil
        location = WeatherLocation(location: city, isLoading: true)
        do {
            location = try await viewModel.selectCity(city)
        } catch {
            location = WeatherLocation(location: city)
            errorMessage = "Failed to load weather: \(error.localizedDescription)"
        }
    }

    var body: some View {
        HStack {
            Button {
                if !viewModel.query.isEmpty {
                    isSearchFocused.wrappedValue = false
                    Task {
                        if !viewModel.results.isEmpty {
                            await selectFirstResult()
                        } else {
                            await viewModel.search()
                            await selectFirstResult()
                        }
                    }
                }
            } label: {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.white)
                    .padding(10)
            }
            .background(Color.gray)
            .clipShape(Circle())
            
            TextField("Search", text: $viewModel.query)
                .focused(isSearchFocused)
                .padding(7)
                .background(Color.white)
                .cornerRadius(10)
                .padding(10)
                .submitLabel(.search)
                .onSubmit {
                    Task {
                        if !viewModel.results.isEmpty {
                            await selectFirstResult()
                        } else {
                            await viewModel.search()
                            await selectFirstResult()
                        }
                    }
                }
                .onChange(of: viewModel.query) { newValue in
                    errorMessage = nil   // Clear error when user types
                    viewModel.handleTypingDebounced()
                }
            
            Button {
                errorMessage = nil
                locationManager.requestLocation()
                // Catch sync errors (permission denied) — onChange won't fire
                // if the value is the same as before
                if let err = locationManager.errorMessage {
                    errorMessage = err
                }
            } label: {
                if locationManager.isLocating == true {
                    ProgressView().padding(10)
                } else {
                    Image(systemName: "location.fill")
                        .foregroundColor(.white)
                        .padding(10)
                }
            }
            .background(Color.gray)
            .clipShape(Circle())
        }
        .padding(10)
        .onAppear {
            // Geolocation is the default — show loading immediately on launch
            location = WeatherLocation(isLoading: true)
            locationManager.requestLocation()
        }
        // When GPS returns coordinates: fetch weather + reverse geocode in parallel
        .onChange(of: locationManager.location) { newLocation in
            if let loc = newLocation {
                Task {
                    errorMessage = nil
                    location = WeatherLocation(isLoading: true)
                    
                    // Start reverse geocoding in parallel
                    async let cityTask = reverseGeocode(
                        latitude: loc.latitude,
                        longitude: loc.longitude
                    )
                    
                    // Fetch weather
                    var weather: WeatherResponse? = nil
                    do {
                        weather = try await fetchWeather(
                            latitude: loc.latitude,
                            longitude: loc.longitude
                        )
                    } catch {
                        errorMessage = "Failed to load weather: \(error.localizedDescription)"
                    }
                    
                    // Await reverse geocoding result (already running in parallel)
                    let city = await cityTask
                    
                    location = WeatherLocation(
                        location: city,
                        weatherData: weather
                    )
                }
            }
        }
        // When location permission is denied or errors occur
        .onChange(of: locationManager.errorMessage) { newError in
            if let err = newError {
                errorMessage = err
            }
        }
    }
}
