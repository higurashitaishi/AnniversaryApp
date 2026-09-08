//
//  SettingsStore.swift
//  WeatherApp
//
//  APIキー・場所・通知時刻などの設定を UserDefaults に保存／読み込みする。
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class SettingsStore: ObservableObject {

    private enum Keys {
        static let apiKey = "apiKey"
        static let location = "location"
        static let hour = "notificationHour"
        static let minute = "notificationMinute"
        static let enabled = "notificationsEnabled"
    }

    private let defaults = UserDefaults.standard

    @Published var apiKey: String {
        didSet { defaults.set(apiKey, forKey: Keys.apiKey) }
    }

    @Published var location: SavedLocation? {
        didSet { saveLocation() }
    }

    @Published var notificationHour: Int {
        didSet { defaults.set(notificationHour, forKey: Keys.hour) }
    }

    @Published var notificationMinute: Int {
        didSet { defaults.set(notificationMinute, forKey: Keys.minute) }
    }

    @Published var notificationsEnabled: Bool {
        didSet { defaults.set(notificationsEnabled, forKey: Keys.enabled) }
    }

    init() {
        self.apiKey = defaults.string(forKey: Keys.apiKey) ?? ""

        if let data = defaults.data(forKey: Keys.location),
           let decoded = try? JSONDecoder().decode(SavedLocation.self, from: data) {
            self.location = decoded
        } else {
            self.location = nil
        }

        // 初期値: 通知時刻は朝 7:00、通知はオフ
        self.notificationHour = defaults.object(forKey: Keys.hour) as? Int ?? 7
        self.notificationMinute = defaults.object(forKey: Keys.minute) as? Int ?? 0
        self.notificationsEnabled = defaults.bool(forKey: Keys.enabled)
    }

    private func saveLocation() {
        if let location, let data = try? JSONEncoder().encode(location) {
            defaults.set(data, forKey: Keys.location)
        } else {
            defaults.removeObject(forKey: Keys.location)
        }
    }

    /// DatePicker と双方向バインドするための Date 表現。時刻部分のみを扱う。
    var notificationTime: Date {
        get {
            var comps = DateComponents()
            comps.hour = notificationHour
            comps.minute = notificationMinute
            return Calendar.current.date(from: comps) ?? Date()
        }
        set {
            let comps = Calendar.current.dateComponents([.hour, .minute], from: newValue)
            notificationHour = comps.hour ?? 7
            notificationMinute = comps.minute ?? 0
        }
    }

    /// 設定が揃っていて天気を取得できる状態かどうか。
    var isReady: Bool {
        !apiKey.isEmpty && location != nil
    }
}
