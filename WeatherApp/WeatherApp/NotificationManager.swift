//
//  NotificationManager.swift
//  WeatherApp
//
//  ローカル通知の許可リクエストとスケジュールを担当する。
//

import Foundation
import UserNotifications
import Combine

@MainActor
final class NotificationManager: NSObject, ObservableObject {

    static let shared = NotificationManager()

    /// 翌日天気の通知に使う固定の識別子。常に上書きするので 1 件だけ存在する。
    static let requestIdentifier = "tomorrowWeatherNotification"

    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined

    private let center = UNUserNotificationCenter.current()

    override init() {
        super.init()
        center.delegate = self
    }

    // MARK: - 許可

    /// 通知の許可をリクエストする。許可されたら true。
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            await refreshStatus()
            return granted
        } catch {
            await refreshStatus()
            return false
        }
    }

    /// 現在の許可状態を取り直す。
    func refreshStatus() async {
        let settings = await center.notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }

    // MARK: - スケジュール

    /// 翌日の天気を、次にやってくる指定時刻に通知するよう予約する。
    ///
    /// 内容は呼び出し時点の予報を埋め込む（非リピート）。アプリ起動時やバックグラウンド更新の
    /// たびに呼び直すことで、最新の予報に更新し続ける設計。
    func scheduleTomorrowNotification(locationName: String,
                                      forecast: DailyForecast,
                                      hour: Int,
                                      minute: Int) async {
        // 既存の予約を消してから入れ直す
        center.removePendingNotificationRequests(withIdentifiers: [Self.requestIdentifier])

        let content = UNMutableNotificationContent()
        content.title = "\(locationName)の明日の天気"
        content.body = "\(forecast.description)　最高\(forecast.maxTempText) / 最低\(forecast.minTempText)　降水確率\(forecast.popText)"
        content.sound = .default

        var comps = DateComponents()
        comps.hour = hour
        comps.minute = minute
        // 「次にやってくる hour:minute」に 1 回だけ発火させる
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)

        let request = UNNotificationRequest(identifier: Self.requestIdentifier,
                                            content: content,
                                            trigger: trigger)
        do {
            try await center.add(request)
        } catch {
            print("通知の予約に失敗しました: \(error)")
        }
    }

    /// 予約済みの通知をすべて取り消す。
    func cancelAll() {
        center.removePendingNotificationRequests(withIdentifiers: [Self.requestIdentifier])
    }
}

// MARK: - フォアグラウンドでも通知を出す

extension NotificationManager: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
                                            willPresent notification: UNNotification) async
        -> UNNotificationPresentationOptions {
        [.banner, .sound, .list]
    }
}
