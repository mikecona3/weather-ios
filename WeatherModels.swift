//
//  WeatherModels.swift
//  WeatherApp
//
//  Codable models mirroring the JSON shape returned by the Flask backend
//  (backend/app.py), which itself mirrors api.weather.gov's response shape.
//

import SwiftUI

struct LocationInfo: Codable {
    let city: String?
    let state: String?
    let office: String?
}

struct DailyPeriod: Codable, Identifiable {
    var id: Int { number }
    let number: Int
    let name: String
    let isDaytime: Bool
    let temperature: Int
    let temperatureUnit: String
    let windSpeed: String
    let windDirection: String
    let shortForecast: String
    let detailedForecast: String
}

struct PrecipProbability: Codable {
    let value: Int?
}

struct HourlyPeriod: Codable, Identifiable {
    var id: String { startTime }
    let startTime: String
    let temperature: Int
    let temperatureUnit: String
    let shortForecast: String
    let probabilityOfPrecipitation: PrecipProbability?

    /// Convenience: parses `startTime` ("2026-09-13T14:00:00-04:00") into a Date.
    var date: Date? {
        ISO8601DateFormatter().date(from: startTime)
    }
}

struct ForecastResponse: Codable {
    let location: LocationInfo
    let updated: String?
    let dailyPeriods: [DailyPeriod]
    let hourlyPeriods: [HourlyPeriod]

    enum CodingKeys: String, CodingKey {
        case location, updated
        case dailyPeriods = "daily_periods"
        case hourlyPeriods = "hourly_periods"
    }
}

struct DiscussionResponse: Codable {
    let office: String?
    let text: String?
}

struct AlertProperties: Codable {
    let event: String?
    let headline: String?
    let description: String?
}

struct AlertFeature: Codable, Identifiable {
    var id: String { properties.event ?? UUID().uuidString }
    let properties: AlertProperties
}

struct AlertsResponse: Codable {
    let alerts: [AlertFeature]
}

/// A single day's forecast, paired from the daytime/nighttime periods NWS
/// returns separately — built in WeatherService, not decoded directly.
struct DayForecast: Identifiable {
    let id = UUID()
    let dayName: String
    let shortForecast: String
    let high: Int
    let low: Int
    let condition: WeatherCondition
}

/// Maps NWS's free-text `shortForecast` strings to an SF Symbol + accent
/// gradient, Pixel-Weather-style. Falls back to a sensible default for text
/// we don't recognize since NWS phrasing varies a lot ("Slight Chance
/// Showers And Thunderstorms" etc.).
enum WeatherCondition {
    case clear, partlyCloudy, cloudy, rain, thunderstorm, snow, fog, windy

    static func from(shortForecast: String) -> WeatherCondition {
        let text = shortForecast.lowercased()
        if text.contains("thunder") { return .thunderstorm }
        if text.contains("snow") || text.contains("flurries") || text.contains("sleet") { return .snow }
        if text.contains("rain") || text.contains("shower") || text.contains("drizzle") { return .rain }
        if text.contains("fog") || text.contains("haze") || text.contains("mist") { return .fog }
        if text.contains("wind") { return .windy }
        if text.contains("mostly cloudy") || text.contains("overcast") { return .cloudy }
        if text.contains("partly") || text.contains("mostly sunny") || text.contains("mostly clear") { return .partlyCloudy }
        if text.contains("clear") || text.contains("sunny") { return .clear }
        return .partlyCloudy
    }

    var sfSymbol: String {
        switch self {
        case .clear: return "sun.max.fill"
        case .partlyCloudy: return "cloud.sun.fill"
        case .cloudy: return "cloud.fill"
        case .rain: return "cloud.rain.fill"
        case .thunderstorm: return "cloud.bolt.rain.fill"
        case .snow: return "cloud.snow.fill"
        case .fog: return "cloud.fog.fill"
        case .windy: return "wind"
        }
    }

    /// Gradient stops, top-to-bottom — mirrors the way Google's Pixel
    /// weather app tints the whole screen by condition rather than using
    /// a neutral card background.
    var gradient: [Color] {
        switch self {
        case .clear:
            return [Color(red: 0.29, green: 0.56, blue: 0.89), Color(red: 0.55, green: 0.78, blue: 0.98)]
        case .partlyCloudy:
            return [Color(red: 0.36, green: 0.53, blue: 0.75), Color(red: 0.62, green: 0.73, blue: 0.85)]
        case .cloudy:
            return [Color(red: 0.42, green: 0.47, blue: 0.53), Color(red: 0.62, green: 0.66, blue: 0.70)]
        case .rain:
            return [Color(red: 0.27, green: 0.35, blue: 0.47), Color(red: 0.45, green: 0.54, blue: 0.63)]
        case .thunderstorm:
            return [Color(red: 0.18, green: 0.20, blue: 0.28), Color(red: 0.38, green: 0.38, blue: 0.48)]
        case .snow:
            return [Color(red: 0.55, green: 0.63, blue: 0.72), Color(red: 0.80, green: 0.85, blue: 0.90)]
        case .fog:
            return [Color(red: 0.55, green: 0.57, blue: 0.60), Color(red: 0.74, green: 0.75, blue: 0.77)]
        case .windy:
            return [Color(red: 0.40, green: 0.58, blue: 0.60), Color(red: 0.62, green: 0.78, blue: 0.76)]
        }
    }
}
