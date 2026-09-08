//
//  SettingsView.swift
//  WeatherApp
//
//  APIキー・場所・通知時刻・通知オンオフを設定する画面。
//

import SwiftUI
import UserNotifications

struct SettingsView: View {
    @EnvironmentObject private var settings: SettingsStore
    @Environment(\.dismiss) private var dismiss
    @StateObject private var notificationManager = NotificationManager.shared

    @State private var showingLocationSearch = false
    @State private var permissionDenied = false

    var body: some View {
        NavigationStack {
            Form {
                // MARK: 場所
                Section("場所") {
                    Button {
                        showingLocationSearch = true
                    } label: {
                        HStack {
                            Label("天気を知りたい場所", systemImage: "mappin.and.ellipse")
                                .foregroundStyle(.primary)
                            Spacer()
                            Text(settings.location?.name ?? "未設定")
                                .foregroundStyle(.secondary)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }

                // MARK: 通知
                Section {
                    Toggle("翌日の天気を通知する", isOn: $settings.notificationsEnabled)
                        .onChange(of: settings.notificationsEnabled) { _, enabled in
                            if enabled { Task { await enableNotifications() } }
                        }

                    DatePicker("通知する時刻",
                               selection: Binding(
                                   get: { settings.notificationTime },
                                   set: { settings.notificationTime = $0 }),
                               displayedComponents: .hourAndMinute)
                        .disabled(!settings.notificationsEnabled)
                } header: {
                    Text("通知")
                } footer: {
                    if permissionDenied {
                        Text("通知が許可されていません。iOS の「設定 > 通知」から許可してください。")
                            .foregroundStyle(.orange)
                    } else {
                        Text("設定した時刻に、その翌日の天気をお知らせします。")
                    }
                }

                // MARK: APIキー
                Section {
                    SecureField("OpenWeatherMap APIキー", text: $settings.apiKey)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } header: {
                    Text("APIキー")
                } footer: {
                    Text("openweathermap.org で無料登録すると取得できます。")
                }
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完了") { dismiss() }
                }
            }
            .sheet(isPresented: $showingLocationSearch) {
                LocationSearchView()
                    .environmentObject(settings)
            }
            .task {
                await notificationManager.refreshStatus()
                updatePermissionFlag()
            }
        }
    }

    private func enableNotifications() async {
        let granted = await notificationManager.requestAuthorization()
        if !granted {
            // 許可されなければトグルを戻す
            settings.notificationsEnabled = false
        }
        updatePermissionFlag()
    }

    private func updatePermissionFlag() {
        permissionDenied = settings.notificationsEnabled &&
            notificationManager.authorizationStatus == .denied
    }
}
