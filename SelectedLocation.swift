//
//  SelectedLocation.swift
//  WeatherApp
//

import CoreLocation

struct SelectedLocation: Equatable {
    let name: String
    let latitude: Double
    let longitude: Double

    static let `default` = SelectedLocation(name: "Binghamton, NY", latitude: 42.0987, longitude: -75.9180)
}
