//
//  Search.swift
//  medium_weather_app
//
//  Created by Aleksandra Kachanova on 24/11/2025.
//

import Combine
import Foundation


@MainActor
class SearchViewModel: ObservableObject {
    @Published var query: String = ""
    @Published var results: [CitySuggestion] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    
    private var debounceTimer: Timer?
    private var currentSearchTask: Task<Void, Never>?

    deinit {
        // CRITICAL: Invalidate timer when view model is deallocated
        // Without this, the timer keeps a strong reference to the closure,
        // which keeps self alive, preventing deallocation
        debounceTimer?.invalidate()
        
        // Cancel any ongoing search task to prevent it from updating
        // properties after the view model is deallocated
        currentSearchTask?.cancel()
    }

    func search() async {
        // Ignore empty input
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if (trimmed.isEmpty || trimmed.count < 2) {
            results = []
            errorMessage = nil
            return
        }

        // Cancel any previous search task to avoid race conditions
        // where an older, slower search completes after a newer one
        currentSearchTask?.cancel()
        
        // Create a new task and store it so we can cancel it if needed
        currentSearchTask = Task {
            isLoading = true
            errorMessage = nil

            do {
                // 1) Build URL
                let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                let urlString = """
                https://geocoding-api.open-meteo.com/v1/search?name=\(encoded)&count=20&language=en&format=json
                """
                guard let url = URL(string: urlString) else {
                    throw URLError(.badURL)
                }

                // 2) Make request
                // Check if task was cancelled before making network call
                try Task.checkCancellation()
                let (data, _) = try await URLSession.shared.data(from: url)

                // 3) Decode JSON
                // Check again after network call completes
                try Task.checkCancellation()
                let decoded = try JSONDecoder().decode(GeocodingResponse.self, from: data)

                // 4) Update results (on main actor because of @MainActor)
                // Only update if task wasn't cancelled
                if !Task.isCancelled {
                    self.results = decoded.results ?? []

                    if self.results.isEmpty {
                        self.errorMessage = "No results for \"\(trimmed)\""
                    }
                }

            } catch {
                // Don't update UI if task was cancelled or view model is deallocated
                if !Task.isCancelled {
                    self.results = []                      // make sure list is empty on error
                    self.errorMessage = "Failed to load results"
                    print("Search error:", error)
                }
            }

            if !Task.isCancelled {
                isLoading = false
            }
        }
        
        // Wait for the task to complete (or be cancelled)
        // This ensures we don't return until the task finishes
        _ = await currentSearchTask?.result
    }
    
    
    func handleTypingDebounced() {
        // Cancel previous timer
        debounceTimer?.invalidate()
        
        // Start a new one
        debounceTimer = Timer.scheduledTimer(withTimeInterval: 0.35, repeats: false) { [weak self] _ in
            Task { await self?.search() }
        }
    }
    
    func selectCity(_ city: CitySuggestion) async throws -> WeatherLocation {
        // 1. Clear search UI
        results = []
        query = ""
        
        // 2. Fetch weather data using shared helper (throws on failure)
        let weatherResponse = try await fetchWeather(
            latitude: city.latitude,
            longitude: city.longitude
        )
        return WeatherLocation(
            location: city,
            weatherData: weatherResponse
        )
    }
}
