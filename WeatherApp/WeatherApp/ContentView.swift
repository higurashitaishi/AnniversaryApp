//
//  ContentView.swift
//  WeatherApp
//
//  メイン画面。明日以降の天気と、次回の通知予定を表示する。
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var settings: SettingsStore
    @StateObject private var viewModel: WeatherViewModel
    @State private var showingSettings = false

    init(settings: SettingsStore) {
        _viewModel = StateObject(wrappedValue: WeatherViewModel(settings: settings))
    }

    var body: some View {
        NavigationStack {
            Group {
                if !settings.isReady {
                    setupPrompt
                } else {
                    forecastList
                }
            }
            .navigationTitle("お天気通知")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
                    .environmentObject(settings)
            }
            .onChange(of: showingSettings) { _, isShowing in
                // 設定画面を閉じたら最新の設定で取り直す
                if !isShowing {
                    Task { await viewModel.refresh() }
                }
            }
            .task {
                await viewModel.refresh()
            }
            .refreshable {
                await viewModel.refresh()
            }
        }
    }

    // MARK: - 設定がまだのときの案内

    private var setupPrompt: some View {
        ContentUnavailableView {
            Label("はじめに設定しましょう", systemImage: "cloud.sun")
        } description: {
            Text("OpenWeatherMap の APIキーと、天気を知りたい場所を設定すると予報が表示されます。")
        } actions: {
            Button("設定を開く") { showingSettings = true }
                .buttonStyle(.borderedProminent)
        }
    }

    // MARK: - 予報一覧

    private var forecastList: some View {
        List {
            if let info = viewModel.nextNotificationInfo {
                Section("次回の通知") {
                    NextNotificationCard(info: info)
                }
            }

            if let message = viewModel.errorMessage {
                Section {
                    Label(message, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                }
            }

            Section(settings.location.map { "\($0.name) の予報" } ?? "予報") {
                if viewModel.dailyForecasts.isEmpty && !viewModel.isLoading {
                    Text("予報データがありません。")
                        .foregroundStyle(.secondary)
                }
                ForEach(viewModel.dailyForecasts) { day in
                    DailyForecastRow(forecast: day)
                }
            }

            if let updated = viewModel.lastUpdated {
                Section {
                    Text("\(DateFormatters.updated.string(from: updated)) 更新")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .overlay {
            if viewModel.isLoading && viewModel.dailyForecasts.isEmpty {
                ProgressView("読み込み中…")
            }
        }
    }
}

// MARK: - 行コンポーネント

private struct DailyForecastRow: View {
    let forecast: DailyForecast

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: forecast.symbolName)
                .symbolRenderingMode(.multicolor)
                .font(.title)
                .frame(width: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text(DateFormatters.dayWithWeekday.string(from: forecast.date))
                    .font(.headline)
                Text(forecast.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(forecast.maxTempText) / \(forecast.minTempText)")
                    .font(.callout)
                    .monospacedDigit()
                Label(forecast.popText, systemImage: "umbrella")
                    .font(.caption)
                    .foregroundStyle(.blue)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct NextNotificationCard: View {
    let info: WeatherViewModel.NextNotificationInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label {
                Text("\(DateFormatters.dayWithWeekday.string(from: info.fireDate)) \(DateFormatters.time.string(from: info.fireDate)) に通知")
                    .font(.headline)
            } icon: {
                Image(systemName: "bell.badge")
            }
            Text("内容：\(DateFormatters.dayWithWeekday.string(from: info.targetDay))は \(info.forecast.description)、最高\(info.forecast.maxTempText) / 最低\(info.forecast.minTempText)、降水確率\(info.forecast.popText)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}
