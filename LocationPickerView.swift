//
//  LocationPickerView.swift
//  WeatherApp
//

import SwiftUI
import MapKit

struct LocationPickerView: View {
    let onSelect: (SelectedLocation) -> Void

    @StateObject private var search = LocationSearchService()
    @StateObject private var currentLocation = CurrentLocationProvider()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        Task {
                            if let location = await currentLocation.requestCurrentLocation() {
                                onSelect(location)
                                dismiss()
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: "location.fill")
                                .foregroundStyle(.blue)
                            Text("Use Current Location")
                            Spacer()
                            if currentLocation.isResolving {
                                ProgressView()
                            }
                        }
                    }
                    if let error = currentLocation.errorMessage {
                        Text(error)
                            .font(.system(size: 12))
                            .foregroundStyle(.red)
                    }
                }

                if !search.results.isEmpty {
                    Section("Results") {
                        ForEach(search.results, id: \.self) { completion in
                            Button {
                                Task {
                                    if let location = await search.resolve(completion) {
                                        onSelect(location)
                                        dismiss()
                                    }
                                }
                            } label: {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(completion.title)
                                        .foregroundStyle(.primary)
                                    if !completion.subtitle.isEmpty {
                                        Text(completion.subtitle)
                                            .font(.system(size: 12))
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .searchable(text: $search.queryFragment, prompt: "Search city or town")
            .navigationTitle("Change Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
