//
//  Location.swift
//  medium_weather_app
//
//  Created by Aleksandra Kachanova on 18/11/2025.
//


import SwiftUI
import CoreLocation
import Foundation
import Combine
import Network

class NetworkMonitor: ObservableObject {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")

    @Published var isConnected = true

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = (path.status == .satisfied)
            }
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }
}

// Make CLLocationCoordinate2D Equatable so we can use .onChange(of:) with it
extension CLLocationCoordinate2D: @retroactive Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    let manager = CLLocationManager()

    @Published var location: CLLocationCoordinate2D?
    @Published var authorizationStatus: CLAuthorizationStatus?
    @Published var errorMessage: String?
    @Published var isLocating: Bool = false

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }
    
    deinit {
        // CRITICAL: Break the retain cycle by setting delegate to nil
        // CLLocationManager holds a strong reference to its delegate,
        // and LocationManager holds a strong reference to CLLocationManager.
        // Without this, LocationManager will never be deallocated.
        manager.delegate = nil
    }

    func requestLocation() {
        errorMessage = nil
        let status = manager.authorizationStatus
        authorizationStatus = status

        switch status {
        case .notDetermined:
            // First time
            isLocating = true
            manager.requestWhenInUseAuthorization()

        case .authorizedWhenInUse, .authorizedAlways:
            // Already allowed
            isLocating = true
            manager.requestLocation()

        case .denied, .restricted:
            // User said "Don’t allow" or cannot use location
            isLocating = false
            location = nil
            errorMessage = "Location permission denied. You can enable it in Settings."

        @unknown default:
            isLocating = false
            location = nil
            errorMessage = "Unknown location permission state."
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = locations.first?.coordinate
        errorMessage = nil
        isLocating = false
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error:", error.localizedDescription)
        errorMessage = "Location error: \(error.localizedDescription)"
        isLocating = false
    }
    
    // Called whenever the user changes permission in the popup
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        authorizationStatus = status

        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()

        case .denied, .restricted:
            errorMessage = "Location permission denied. You can enable it in Settings."
            location = nil
            isLocating = false

        default:
            break
        }
    }
}
