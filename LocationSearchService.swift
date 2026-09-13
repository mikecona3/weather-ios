//
//  LocationSearchService.swift
//  WeatherApp
//
//  Two pieces: live-typing search suggestions via MKLocalSearchCompleter
//  (same API behind Apple Maps' search bar), and a one-shot "use my
//  current location" helper via CoreLocation.
//

import CoreLocation
import MapKit

@MainActor
final class LocationSearchService: NSObject, ObservableObject {
    @Published var queryFragment: String = "" {
        didSet { completer.queryFragment = queryFragment }
    }
    @Published var results: [MKLocalSearchCompletion] = []

    private let completer: MKLocalSearchCompleter

    override init() {
        completer = MKLocalSearchCompleter()
        super.init()
        completer.delegate = self
        // Cities/towns only — not points of interest, addresses, etc.
        completer.resultTypes = .address
    }

    /// Resolves a tapped suggestion to an actual coordinate.
    func resolve(_ completion: MKLocalSearchCompletion) async -> SelectedLocation? {
        let request = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: request)
        do {
            let response = try await search.start()
            guard let item = response.mapItems.first else { return nil }
            let name = completion.title.isEmpty ? (item.name ?? "Unknown") : completion.title
            return SelectedLocation(
                name: name,
                latitude: item.placemark.coordinate.latitude,
                longitude: item.placemark.coordinate.longitude
            )
        } catch {
            return nil
        }
    }
}

extension LocationSearchService: MKLocalSearchCompleterDelegate {
    nonisolated func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        Task { @MainActor in
            self.results = completer.results
        }
    }

    nonisolated func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        Task { @MainActor in
            self.results = []
        }
    }
}

/// One-shot current-location lookup. Requires adding
/// `NSLocationWhenInUseUsageDescription` to Info.plist — see ios/README.md.
@MainActor
final class CurrentLocationProvider: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var isResolving = false
    @Published var errorMessage: String?

    private let manager = CLLocationManager()
    private var continuation: CheckedContinuation<SelectedLocation?, Never>?

    override init() {
        super.init()
        manager.delegate = self
    }

    func requestCurrentLocation() async -> SelectedLocation? {
        isResolving = true
        errorMessage = nil
        defer { isResolving = false }

        let status = manager.authorizationStatus
        if status == .notDetermined {
            manager.requestWhenInUseAuthorization()
        } else if status == .denied || status == .restricted {
            errorMessage = "Location access denied — enable it in Settings to use this."
            return nil
        }

        return await withCheckedContinuation { continuation in
            self.continuation = continuation
            manager.requestLocation()
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            guard let location = locations.first else {
                self.continuation?.resume(returning: nil)
                self.continuation = nil
                return
            }
            let geocoder = CLGeocoder()
            let placemarks = try? await geocoder.reverseGeocodeLocation(location)
            let name = placemarks?.first.map { placemark in
                [placemark.locality, placemark.administrativeArea]
                    .compactMap { $0 }
                    .joined(separator: ", ")
            } ?? "Current Location"

            self.continuation?.resume(returning: SelectedLocation(
                name: name.isEmpty ? "Current Location" : name,
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude
            ))
            self.continuation = nil
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.errorMessage = "Couldn't get your location."
            self.continuation?.resume(returning: nil)
            self.continuation = nil
        }
    }
}
