//
//  WeatherViewModel.swift
//  WeatherApp
//
//  予報の取得・画面状態の保持・通知の予約をまとめる中心的なクラス。
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class WeatherViewModel: ObservableObject {

    @Published var dailyForecasts: [DailyForecast] = []   // これから数日分（明日以降）
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var lastUpdated: Date?
    /// 次回の通知予定（場所名・対象日・発火時刻）を画面に出すための情報。
    @Published var nextNotificationInfo: NextNotificationInfo?

    struct NextNotificationInfo {
        let fireDate: Date      // 通知が鳴る日時
        let targetDay: Date     // 通知で知らせる「翌日」
        let forecast: DailyForecast
    }

    private let settings: SettingsStore
    private let calendar = Calendar.current

    init(settings: SettingsStore) {
        self.settings = settings
    }

    /// 予報を取り直し、必要なら通知を予約し直す。アプリ起動・前面復帰・設定変更時に呼ぶ。
    func refresh() async {
        guard !settings.apiKey.isEmpty else {
            errorMessage = WeatherError.missingAPIKey.localizedDescription
            return
        }
        guard let location = settings.location else {
            errorMessage = WeatherError.missingLocation.localizedDescription
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let service = WeatherService(apiKey: settings.apiKey)
        do {
            let entries = try await service.fetchForecast(lat: location.latitude,
                                                          lon: location.longitude)
            updateDisplay(from: entries, service: service)
            lastUpdated = Date()
            await scheduleIfNeeded(entries: entries,
                                   service: service,
                                   locationName: location.name)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    // MARK: - 画面用の予報リストを作る

    private func updateDisplay(from entries: [ForecastEntry], service: WeatherService) {
        let today = calendar.startOfDay(for: Date())
        // 明日から最大 5 日分を作る（データがある日だけ）
        let days = (1...5).compactMap { offset -> DailyForecast? in
            guard let day = calendar.date(byAdding: .day, value: offset, to: today) else { return nil }
            return service.dailyForecast(for: day, from: entries)
        }
        dailyForecasts = days
    }

    // MARK: - 通知の予約

    private func scheduleIfNeeded(entries: [ForecastEntry],
                                  service: WeatherService,
                                  locationName: String) async {
        let manager = NotificationManager.shared
        await manager.refreshStatus()

        guard settings.notificationsEnabled,
              manager.authorizationStatus == .authorized else {
            manager.cancelAll()
            nextNotificationInfo = nil
            return
        }

        // 次にやってくる「指定時刻」を求める
        var timeComps = DateComponents()
        timeComps.hour = settings.notificationHour
        timeComps.minute = settings.notificationMinute
        guard let fireDate = calendar.nextDate(after: Date(),
                                               matching: timeComps,
                                               matchingPolicy: .nextTime) else { return }

        // 通知が鳴る日の「翌日」を対象にする
        guard let targetDay = calendar.date(byAdding: .day, value: 1,
                                            to: calendar.startOfDay(for: fireDate)),
              let forecast = service.dailyForecast(for: targetDay, from: entries) else {
            // 翌日のデータがまだ無い場合は予約をスキップ
            nextNotificationInfo = nil
            return
        }

        await manager.scheduleTomorrowNotification(locationName: locationName,
                                                   forecast: forecast,
                                                   hour: settings.notificationHour,
                                                   minute: settings.notificationMinute)

        nextNotificationInfo = NextNotificationInfo(fireDate: fireDate,
                                                    targetDay: targetDay,
                                                    forecast: forecast)
    }
}
