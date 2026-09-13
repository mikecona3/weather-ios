//
//  ForecastDiscussionCard.swift
//  WeatherApp
//

import SwiftUI

struct ForecastDiscussionCard: View {
    let office: String
    let text: String

    @State private var expanded = false

    private var excerpt: String {
        let paragraphs = text.components(separatedBy: "\n\n")
        let shown = expanded ? paragraphs : Array(paragraphs.prefix(1))
        return shown.joined(separator: "\n\n")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("FORECAST DISCUSSION")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.75))
                Spacer()
                Text("NWS \(office)")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.6))
            }

            Text(excerpt)
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.9))
                .lineSpacing(4)

            Button(expanded ? "Show less" : "Read more") {
                withAnimation(.easeInOut(duration: 0.2)) { expanded.toggle() }
            }
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(.white)
        }
        .padding(18)
        .background(.white.opacity(0.14), in: RoundedRectangle(cornerRadius: 20))
    }
}

/// Severe weather banner — this is where the tornado/rotation module's
/// output would eventually surface too, not just NWS text alerts.
struct AlertBanner: View {
    let alert: AlertFeature

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.white)
            VStack(alignment: .leading, spacing: 2) {
                Text(alert.properties.event ?? "Weather Alert")
                    .font(.system(size: 14, weight: .semibold))
                if let headline = alert.properties.headline {
                    Text(headline)
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.9))
                }
            }
            Spacer()
        }
        .foregroundStyle(.white)
        .padding(14)
        .background(Color(red: 0.69, green: 0.33, blue: 0.23), in: RoundedRectangle(cornerRadius: 14))
    }
}
