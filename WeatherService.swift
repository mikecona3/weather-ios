//
//  WeatherService.swift
//  WeatherApp
//
//  Talks to the Flask backend (../backend/app.py), which wraps NOAA's
//  api.weather.gov. Real network calls are written below but commented
//  out — mock data is active so the UI is usable standalone right now.
//
//  TO GO LIVE:
//  1. Run the Python backend: `python backend/app.py` (see project README)
//  2. Set `baseURL` below to wherever that's reachable —
//     "http://localhost:5000" only works in the Simulator; a physical
//     device needs your Mac's LAN IP (e.g. "http://192.168.1.23:5000"),
//     or a deployed URL once the backend is hosted somewhere.
//  3. Uncomment the `live...` implementations and swap the `mock...` calls
//     for them in each function body below.
//

import Foundation

@MainActor
final class WeatherService: ObservableObject {

    // MARK: - Config

    /// Backend base URL. Only relevant once live calls are uncommented.
    private let baseURL = "http://localhost:5000"

    // MARK: - Published state

    @Published var selectedLocation: SelectedLocation = .default
    @Published var forecast: ForecastResponse?
    @Published var days: [DayForecast] = []
    @Published var discussion: DiscussionResponse?
    @Published var activeAlert: AlertFeature?
    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Public entry point

    func loadAll() async {
        isLoading = true
        errorMessage = nil
        do {
            let forecastResponse = try await fetchForecast()
            self.forecast = forecastResponse
            self.days = Self.pairDailyPeriods(forecastResponse.dailyPeriods)
        } catch {
            errorMessage = "Couldn't load forecast: \(error.localizedDescription)"
        }
        isLoading = false

        // Non-critical panels — fail silently, same as the web frontend.
        discussion = try? await fetchDiscussion()
        activeAlert = try? await fetchAlerts().first
    }

    /// Called from the location picker — updates the active location and
    /// re-fetches everything for it.
    func changeLocation(to location: SelectedLocation) async {
        selectedLocation = location
        await loadAll()
    }

    // MARK: - Forecast

    private func fetchForecast() async throws -> ForecastResponse {
        return try await mockForecast()

        // --- LIVE VERSION (uncomment once the backend is reachable) ---
        // let url = URL(string: "\(baseURL)/api/forecast?lat=\(selectedLocation.latitude)&lon=\(selectedLocation.longitude)")!
        // let (data, response) = try await URLSession.shared.data(from: url)
        // try Self.checkHTTPStatus(response)
        // let decoder = JSONDecoder()
        // return try decoder.decode(ForecastResponse.self, from: data)
    }

    // MARK: - Forecast discussion

    private func fetchDiscussion() async throws -> DiscussionResponse {
        return try await mockDiscussion()

        // --- LIVE VERSION ---
        // let url = URL(string: "\(baseURL)/api/discussion?lat=\(selectedLocation.latitude)&lon=\(selectedLocation.longitude)")!
        // let (data, response) = try await URLSession.shared.data(from: url)
        // try Self.checkHTTPStatus(response)
        // return try JSONDecoder().decode(DiscussionResponse.self, from: data)
    }

    // MARK: - Alerts

    private func fetchAlerts() async throws -> [AlertFeature] {
        return [] // no active alerts in mock mode

        // --- LIVE VERSION ---
        // let url = URL(string: "\(baseURL)/api/alerts?lat=\(selectedLocation.latitude)&lon=\(selectedLocation.longitude)")!
        // let (data, response) = try await URLSession.shared.data(from: url)
        // try Self.checkHTTPStatus(response)
        // let decoded = try JSONDecoder().decode(AlertsResponse.self, from: data)
        // return decoded.alerts
    }

    // MARK: - Helpers

    private static func checkHTTPStatus(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }

    /// NWS returns day/night as separate periods (e.g. "Saturday", "Saturday
    /// Night") — pair them into one row per day the way the web frontend does.
    static func pairDailyPeriods(_ periods: [DailyPeriod]) -> [DayForecast] {
        var result: [DayForecast] = []
        var i = 0
        while i < periods.count && result.count < 5 {
            let period = periods[i]
            guard period.isDaytime else { i += 1; continue }
            let night = (i + 1 < periods.count && !periods[i + 1].isDaytime) ? periods[i + 1] : nil
            result.append(
                DayForecast(
                    dayName: period.name.components(separatedBy: " ").first ?? period.name,
                    shortForecast: period.shortForecast,
                    high: period.temperature,
                    low: night?.temperature ?? period.temperature - 10,
                    condition: .from(shortForecast: period.shortForecast)
                )
            )
            i += 1
        }
        return result
    }

    // MARK: - Mock data (active for now)

    private func mockForecast() async throws -> ForecastResponse {
        try await Task.sleep(nanoseconds: 400_000_000) // simulate network latency

        // Mock temps stay the same regardless of location — this is
        // placeholder data, not a real location-aware forecast. Once the
        // live calls are uncommented, real per-location data comes from NOAA.
        let nameParts = selectedLocation.name.components(separatedBy: ", ")
        let cityComponent = nameParts.first ?? selectedLocation.name
        let stateComponent = nameParts.count > 1 ? nameParts[1] : ""

        let calendar = Calendar.current
        let now = Date()
        let hourly: [HourlyPeriod] = (0..<12).map { offset in
            let date = calendar.date(byAdding: .hour, value: offset, to: now)!
            let temps = [68, 70, 71, 72, 71, 69, 66, 63, 60, 58, 56, 55]
            let pops = [12, 10, 8, 14, 22, 31, 28, 19, 12, 9, 6, 5]
            return HourlyPeriod(
                startTime: ISO8601DateFormatter().string(from: date),
                temperature: temps[offset],
                temperatureUnit: "F",
                shortForecast: "Mostly Cloudy",
                probabilityOfPrecipitation: PrecipProbability(value: pops[offset])
            )
        }

        let daily: [DailyPeriod] = [
            DailyPeriod(number: 1, name: "Today", isDaytime: true, temperature: 72, temperatureUnit: "F", windSpeed: "9 mph", windDirection: "NW", shortForecast: "Mostly Cloudy", detailedForecast: ""),
            DailyPeriod(number: 2, name: "Tonight", isDaytime: false, temperature: 54, temperatureUnit: "F", windSpeed: "6 mph", windDirection: "NW", shortForecast: "Partly Cloudy", detailedForecast: ""),
            DailyPeriod(number: 3, name: "Sunday", isDaytime: true, temperature: 65, temperatureUnit: "F", windSpeed: "12 mph", windDirection: "W", shortForecast: "Scattered Showers", detailedForecast: ""),
            DailyPeriod(number: 4, name: "Sunday Night", isDaytime: false, temperature: 51, temperatureUnit: "F", windSpeed: "8 mph", windDirection: "W", shortForecast: "Chance Showers", detailedForecast: ""),
            DailyPeriod(number: 5, name: "Monday", isDaytime: true, temperature: 63, temperatureUnit: "F", windSpeed: "7 mph", windDirection: "NW", shortForecast: "Sunny", detailedForecast: ""),
            DailyPeriod(number: 6, name: "Monday Night", isDaytime: false, temperature: 46, temperatureUnit: "F", windSpeed: "5 mph", windDirection: "N", shortForecast: "Clear", detailedForecast: ""),
            DailyPeriod(number: 7, name: "Tuesday", isDaytime: true, temperature: 68, temperatureUnit: "F", windSpeed: "6 mph", windDirection: "SW", shortForecast: "Partly Sunny", detailedForecast: ""),
            DailyPeriod(number: 8, name: "Tuesday Night", isDaytime: false, temperature: 49, temperatureUnit: "F", windSpeed: "5 mph", windDirection: "SW", shortForecast: "Mostly Clear", detailedForecast: ""),
            DailyPeriod(number: 9, name: "Wednesday", isDaytime: true, temperature: 70, temperatureUnit: "F", windSpeed: "8 mph", windDirection: "S", shortForecast: "Chance Thunderstorms", detailedForecast: ""),
            DailyPeriod(number: 10, name: "Wednesday Night", isDaytime: false, temperature: 55, temperatureUnit: "F", windSpeed: "7 mph", windDirection: "S", shortForecast: "Thunderstorms", detailedForecast: ""),
        ]

        return ForecastResponse(
            location: LocationInfo(city: cityComponent, state: stateComponent, office: "BGM"),
            updated: ISO8601DateFormatter().string(from: now),
            dailyPeriods: daily,
            hourlyPeriods: hourly
        )
    }

    private func mockDiscussion() async throws -> DiscussionResponse {
        DiscussionResponse(
            office: "BGM",
            text: """
            Broad upper trough easing off to the east through midday leaves the region under weak \
            northwest flow, keeping temperatures a few degrees below seasonal norms for the next \
            48 hours. Sky cover today trending toward partial clearing by afternoon as drier air \
            filters in behind departing cloud deck.

            Attention turns to a weak shortwave dropping southeast Sunday, bringing a slight uptick \
            in shower coverage, mainly after 11 AM. Not expecting anything organized — pop capped \
            in the 30-40% range across the forecast area.

            Midweek system still a few days out remains the bigger question mark; ensemble guidance \
            has trended slightly wetter for Wednesday over the last two cycles.
            """
        )
    }
}
