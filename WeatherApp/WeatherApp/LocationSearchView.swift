//
//  LocationSearchView.swift
//  WeatherApp
//
//  都市名で場所を検索して選ぶ画面。
//

import SwiftUI

struct LocationSearchView: View {
    @EnvironmentObject private var settings: SettingsStore
    @Environment(\.dismiss) private var dismiss

    @State private var query = ""
    @State private var results: [GeoResult] = []
    @State private var isSearching = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            List {
                if let errorMessage {
                    Label(errorMessage, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                }

                if results.isEmpty && !isSearching && errorMessage == nil {
                    Text("都市名を入力して検索してください。\n例：東京、Osaka、London")
                        .foregroundStyle(.secondary)
                }

                ForEach(results) { result in
                    Button {
                        select(result)
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(result.displayName)
                                .foregroundStyle(.primary)
                            Text(String(format: "緯度 %.2f, 経度 %.2f", result.lat, result.lon))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .overlay {
                if isSearching {
                    ProgressView()
                }
            }
            .navigationTitle("場所を検索")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $query, prompt: "都市名")
            .onSubmit(of: .search) {
                Task { await search() }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { dismiss() }
                }
            }
        }
    }

    private func search() async {
        let service = WeatherService(apiKey: settings.apiKey)
        isSearching = true
        errorMessage = nil
        defer { isSearching = false }
        do {
            results = try await service.search(city: query)
            if results.isEmpty {
                errorMessage = "該当する場所が見つかりませんでした。"
            }
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    private func select(_ result: GeoResult) {
        settings.location = result.toSavedLocation()
        dismiss()
    }
}
