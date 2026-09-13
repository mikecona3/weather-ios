//
//  DailyForecastList.swift
//  WeatherApp
//
//  Simple row-per-day list with a min/max range bar, matching the
//  understated daily list at the bottom of Pixel Weather rather than
//  the hairline-table look of the web version.
//

import SwiftUI

struct DailyForecastList: View {
    let days: [DayForecast]

    private var overallRange: (min: Int, max: Int) {
        let lows = days.map(\.low)
        let highs = days.map(\.high)
        return (lows.min() ?? 0, highs.max() ?? 100)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("5-DAY FORECAST")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.75))
                .padding(.leading, 4)
                .padding(.bottom, 6)

            VStack(spacing: 0) {
                ForEach(Array(days.enumerated()), id: \.element.id) { index, day in
                    DailyRow(day: day, range: overallRange)
                    if index < days.count - 1 {
                        Divider().background(.white.opacity(0.15))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
            .background(.white.opacity(0.14), in: RoundedRectangle(cornerRadius: 20))
        }
    }
}

private struct DailyRow: View {
    let day: DayForecast
    let range: (min: Int, max: Int)

    private var span: CGFloat { CGFloat(max(1, range.max - range.min)) }
    private var lowInset: CGFloat { CGFloat(day.low - range.min) / span }
    private var highInset: CGFloat { CGFloat(range.max - day.high) / span }

    var body: some View {
        HStack(spacing: 12) {
            Text(day.dayName)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 74, alignment: .leading)

            Image(systemName: day.condition.sfSymbol)
                .font(.system(size: 17))
                .foregroundStyle(.white)
                .symbolRenderingMode(.multicolor)
                .frame(width: 24)

            Text("\(day.low)°")
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.65))
                .frame(width: 32, alignment: .trailing)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(.white.opacity(0.2))
                    Capsule()
                        .fill(
                            LinearGradient(colors: [.cyan.opacity(0.8), .orange.opacity(0.85)],
                                           startPoint: .leading, endPoint: .trailing)
                        )
                        .padding(.leading, geo.size.width * lowInset)
                        .padding(.trailing, geo.size.width * highInset)
                }
            }
            .frame(height: 4)

            Text("\(day.high)°")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 32, alignment: .trailing)
        }
        .padding(.vertical, 12)
    }
}
