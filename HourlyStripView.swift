//
//  HourlyStripView.swift
//  WeatherApp
//
//  Horizontal scroll of the next 12 hours — glass-chip style over the
//  gradient background, matching the translucent hourly row in Pixel
//  Weather rather than the boxed table look of the web version.
//

import SwiftUI

struct HourlyStripView: View {
    let periods: [HourlyPeriod]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("HOURLY FORECAST")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.75))
                .padding(.leading, 20)

            ScrollView(.horizontal) {
                HStack(spacing: 14) {
                    ForEach(Array(periods.prefix(12))) { period in
                        HourlyChip(period: period)
                    }
                }
                .padding(.horizontal, 20)
            }
            .scrollIndicators(.hidden)
        }
    }
}

private struct HourlyChip: View {
    let period: HourlyPeriod

    private var condition: WeatherCondition { .from(shortForecast: period.shortForecast) }

    private var timeLabel: String {
        guard let date = period.date else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        return formatter.string(from: date)
    }

    var body: some View {
        VStack(spacing: 8) {
            Text(timeLabel)
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.8))

            Image(systemName: condition.sfSymbol)
                .font(.system(size: 20))
                .foregroundStyle(.white)
                .symbolRenderingMode(.multicolor)

            Text("\(period.temperature)°")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)

            if let pop = period.probabilityOfPrecipitation?.value, pop > 0 {
                Text("\(pop)%")
                    .font(.system(size: 11))
                    .foregroundStyle(.cyan.opacity(0.9))
            } else {
                Text(" ")
                    .font(.system(size: 11))
            }
        }
        .frame(width: 58)
        .padding(.vertical, 12)
        .background(.white.opacity(0.14), in: RoundedRectangle(cornerRadius: 18))
    }
}
