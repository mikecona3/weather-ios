//
//  ContentView.swift
//  WeatherApp
//
//  Layout intentionally mirrors Google's Pixel Weather app: a full-bleed
//  gradient background that shifts with current conditions, a big glanceable
//  temperature up top, a horizontally scrolling hourly strip, then a simple
//  daily list — rather than the boxed/card-heavy layout of the web version.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var service = WeatherService()
    @State private var showingLocationPicker = false

    private var condition: WeatherCondition {
        guard let today = service.forecast?.dailyPeriods.first else { return .partlyCloudy }
        return .from(shortForecast: today.shortForecast)
    }

    var body: some View {
        ZStack {
            LinearGradient(colors: condition.gradient, startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            if service.isLoading && service.forecast == nil {
                ProgressView()
                    .tint(.white)
            } else if let error = service.errorMessage, service.forecast == nil {
                errorState(error)
            } else {
                content
            }
        }
        .task {
            await service.loadAll()
        }
        .refreshable {
            await service.loadAll()
        }
        .sheet(isPresented: $showingLocationPicker) {
            LocationPickerView { location in
                Task { await service.changeLocation(to: location) }
            }
        }
    }

    // MARK: - Main content

    private var content: some View {
        ScrollView {
            VStack(spacing: 28) {
                if let alert = service.activeAlert {
                    AlertBanner(alert: alert)
                        .padding(.horizontal)
                }

                header

                heroSection

                if !(service.forecast?.hourlyPeriods.isEmpty ?? true) {
                    HourlyStripView(periods: service.forecast?.hourlyPeriods ?? [])
                }

                if !service.days.isEmpty {
                    DailyForecastList(days: service.days)
                        .padding(.horizontal)
                }

                if let discussion = service.discussion, let text = discussion.text {
                    ForecastDiscussionCard(office: discussion.office ?? "", text: text)
                        .padding(.horizontal)
                }

                Spacer(minLength: 20)
            }
            .padding(.top, 8)
        }
        .scrollIndicators(.hidden)
    }

    private var header: some View {
        Button {
            showingLocationPicker = true
        } label: {
            VStack(spacing: 2) {
                HStack(spacing: 5) {
                    Text(service.forecast?.location.city ?? service.selectedLocation.name)
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(.white)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.75))
                }
                if let updated = service.forecast?.updated {
                    Text("Updated \(Self.relativeTime(updated))")
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.75))
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var heroSection: some View {
        VStack(spacing: 6) {
            Image(systemName: condition.sfSymbol)
                .font(.system(size: 44))
                .foregroundStyle(.white)
                .symbolRenderingMode(.multicolor)

            Text("\(service.forecast?.hourlyPeriods.first?.temperature ?? service.forecast?.dailyPeriods.first?.temperature ?? 0)°")
                .font(.system(size: 96, weight: .thin))
                .foregroundStyle(.white)

            Text(service.forecast?.dailyPeriods.first?.shortForecast ?? "")
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(.white)

            if let first = service.days.first {
                Text("H:\(first.high)°  L:\(first.low)°")
                    .font(.system(size: 15))
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
    }

    private func errorState(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "cloud.slash")
                .font(.system(size: 36))
                .foregroundStyle(.white)
            Text(message)
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.85))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Button("Try Again") {
                Task { await service.loadAll() }
            }
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(condition.gradient.first ?? .blue)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(.white, in: Capsule())
        }
    }

    private static func relativeTime(_ isoString: String) -> String {
        guard let date = ISO8601DateFormatter().date(from: isoString) else { return "" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    ContentView()
}
