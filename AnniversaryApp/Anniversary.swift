//
//  Anniversary.swift
//  AnniversaryApp
//
//  Managers & helpers (notifications, haptics, sample data).
//  NOTE: The Anniversary model itself lives in Models.swift.
//
//  Created by higurashi on 2026/05/29.
//

import Foundation
import UIKit
import SwiftUI
import UserNotifications

// MARK: - Notification Manager

final class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    private let center = UNUserNotificationCenter.current()

    /// Ask the user for permission to post local notifications.
    func requestAuthorization(completion: ((Bool) -> Void)? = nil) {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async { completion?(granted) }
        }
    }

    func authorizationStatus(_ completion: @escaping (UNAuthorizationStatus) -> Void) {
        center.getNotificationSettings { settings in
            DispatchQueue.main.async { completion(settings.authorizationStatus) }
        }
    }

    /// Clear and re-create all pending reminders from the current items.
    func reschedule(for items: [Anniversary]) {
        center.removeAllPendingNotificationRequests()
        for item in items where item.notifyEnabled {
            schedule(item)
        }
    }

    private func schedule(_ item: Anniversary) {
        let calendar = Calendar.current
        guard let fireDate = calendar.date(
            byAdding: .day,
            value: -item.notifyDaysBefore,
            to: item.nextOccurrence
        ) else { return }

        // Fire at 09:00 on the reminder day.
        var comps = calendar.dateComponents([.year, .month, .day], from: fireDate)
        comps.hour = 9
        comps.minute = 0

        guard let trigger = makeTrigger(comps: comps) else { return }

        let content = UNMutableNotificationContent()
        content.title = "\(item.category.label)のリマインド"
        if item.notifyDaysBefore == 0 {
            content.body = "今日は「\(item.title)」です 🎉"
        } else {
            content.body = "「\(item.title)」まであと\(item.notifyDaysBefore)日です"
        }
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: item.id.uuidString,
            content: content,
            trigger: trigger
        )
        center.add(request)
    }

    private func makeTrigger(comps: DateComponents) -> UNCalendarNotificationTrigger? {
        guard let date = Calendar.current.date(from: comps) else { return nil }
        // If the computed fire date is in the past, skip (one-time) — for
        // recurring events the store reschedules on next launch/edit anyway.
        if date < Date() { return nil }
        return UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
    }
}

// MARK: - Haptics

enum Haptics {
    static func tap() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }
}

// MARK: - Sample data

enum SampleData {
    static func make() -> [Anniversary] {
        let cal = Calendar.current
        func date(_ y: Int, _ m: Int, _ d: Int) -> Date {
            cal.date(from: DateComponents(year: y, month: m, day: d)) ?? Date()
        }
        return [
            Anniversary(title: "結婚記念日", date: date(2018, 6, 10), note: "毎年ふたりでお祝い",
                        colorHex: AnniversaryCategory.wedding.defaultColor,
                        category: .wedding, isPinned: true, notifyEnabled: true, notifyDaysBefore: 3,
                        tags: ["family"]),
            Anniversary(title: "はじめてのデート", date: date(2016, 3, 14), note: "映画を観た日",
                        colorHex: AnniversaryCategory.relationship.defaultColor,
                        category: .relationship, tags: ["love"]),
            Anniversary(title: "わたしの誕生日", date: date(1995, 12, 24),
                        colorHex: AnniversaryCategory.birthday.defaultColor,
                        category: .birthday, notifyEnabled: true)
        ]
    }
}
