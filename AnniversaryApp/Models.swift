//
//  Models.swift
//  AnniversaryApp
//
//  Created by higurashi on 2026/05/29.
//

import Foundation
import UIKit
import Combine
import SwiftUI

// MARK: - Category

enum AnniversaryCategory: String, Codable, CaseIterable, Identifiable {
    case anniversary
    case birthday
    case wedding
    case relationship
    case memorial
    case work
    case travel
    case other

    var id: String { rawValue }

    var label: String {
        switch self {
        case .anniversary: return "記念日"
        case .birthday: return "誕生日"
        case .wedding: return "結婚"
        case .relationship: return "交際"
        case .memorial: return "命日"
        case .work: return "仕事"
        case .travel: return "旅行"
        case .other: return "その他"
        }
    }

    var icon: String {
        switch self {
        case .anniversary: return "sparkles"
        case .birthday: return "birthday.cake.fill"
        case .wedding: return "heart.fill"
        case .relationship: return "heart.circle.fill"
        case .memorial: return "leaf.fill"
        case .work: return "briefcase.fill"
        case .travel: return "airplane"
        case .other: return "star.fill"
        }
    }

    var defaultColor: String {
        switch self {
        case .anniversary: return "FFCC02"
        case .birthday: return "FF8E53"
        case .wedding: return "FF6B6B"
        case .relationship: return "F7AEF8"
        case .memorial: return "96CEB4"
        case .work: return "45B7D1"
        case .travel: return "4ECDC4"
        case .other: return "DDA0DD"
        }
    }
}

// MARK: - Repeat Rule

enum RepeatRule: String, Codable, CaseIterable, Identifiable {
    case yearly
    case monthly
    case once

    var id: String { rawValue }

    var label: String {
        switch self {
        case .yearly: return "毎年"
        case .monthly: return "毎月"
        case .once: return "繰り返さない"
        }
    }

    var icon: String {
        switch self {
        case .yearly: return "arrow.triangle.2.circlepath"
        case .monthly: return "calendar"
        case .once: return "1.circle"
        }
    }
}

// MARK: - Model

struct Anniversary: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var title: String
    var date: Date
    var note: String
    var imageData: Data?
    var colorHex: String  // accent color per card
    var category: AnniversaryCategory = .anniversary
    var repeatRule: RepeatRule = .yearly
    var isPinned: Bool = false
    var notifyEnabled: Bool = false
    var notifyDaysBefore: Int = 1
    var tags: [String] = []
    var createdAt: Date = Date()

    // MARK: Backward-compatible decoding

    enum CodingKeys: String, CodingKey {
        case id, title, date, note, imageData, colorHex
        case category, repeatRule, isPinned, notifyEnabled, notifyDaysBefore, tags, createdAt
    }

    init(id: UUID = UUID(),
         title: String,
         date: Date,
         note: String = "",
         imageData: Data? = nil,
         colorHex: String = "FF6B6B",
         category: AnniversaryCategory = .anniversary,
         repeatRule: RepeatRule = .yearly,
         isPinned: Bool = false,
         notifyEnabled: Bool = false,
         notifyDaysBefore: Int = 1,
         tags: [String] = [],
         createdAt: Date = Date()) {
        self.id = id
        self.title = title
        self.date = date
        self.note = note
        self.imageData = imageData
        self.colorHex = colorHex
        self.category = category
        self.repeatRule = repeatRule
        self.isPinned = isPinned
        self.notifyEnabled = notifyEnabled
        self.notifyDaysBefore = notifyDaysBefore
        self.tags = tags
        self.createdAt = createdAt
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        title = try c.decode(String.self, forKey: .title)
        date = try c.decode(Date.self, forKey: .date)
        note = try c.decodeIfPresent(String.self, forKey: .note) ?? ""
        imageData = try c.decodeIfPresent(Data.self, forKey: .imageData)
        colorHex = try c.decodeIfPresent(String.self, forKey: .colorHex) ?? "FF6B6B"
        category = try c.decodeIfPresent(AnniversaryCategory.self, forKey: .category) ?? .anniversary
        repeatRule = try c.decodeIfPresent(RepeatRule.self, forKey: .repeatRule) ?? .yearly
        isPinned = try c.decodeIfPresent(Bool.self, forKey: .isPinned) ?? false
        notifyEnabled = try c.decodeIfPresent(Bool.self, forKey: .notifyEnabled) ?? false
        notifyDaysBefore = try c.decodeIfPresent(Int.self, forKey: .notifyDaysBefore) ?? 1
        tags = try c.decodeIfPresent([String].self, forKey: .tags) ?? []
        createdAt = try c.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
    }

    // MARK: - Computed

    var daysRemaining: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let target = calendar.startOfDay(for: nextOccurrence)
        let components = calendar.dateComponents([.day], from: today, to: target)
        return components.day ?? 0
    }

    var daysSince: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let target = calendar.startOfDay(for: date)
        let components = calendar.dateComponents([.day], from: target, to: today)
        return components.day ?? 0
    }

    var isPast: Bool {
        date < Date()
    }

    var isToday: Bool {
        daysRemaining == 0
    }

    /// The next time this anniversary occurs, honoring the repeat rule.
    var nextOccurrence: Date {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        switch repeatRule {
        case .once:
            return calendar.startOfDay(for: date)

        case .yearly:
            var components = calendar.dateComponents([.month, .day], from: date)
            let thisYear = calendar.component(.year, from: today)
            components.year = thisYear
            if let candidate = calendar.date(from: components), candidate >= today {
                return candidate
            }
            components.year = thisYear + 1
            return calendar.date(from: components) ?? date

        case .monthly:
            let day = calendar.component(.day, from: date)
            var components = calendar.dateComponents([.year, .month], from: today)
            components.day = day
            if let candidate = calendar.date(from: components), candidate >= today {
                return candidate
            }
            // advance one month
            if let base = calendar.date(from: components),
               let next = calendar.date(byAdding: .month, value: 1, to: base) {
                return next
            }
            return date
        }
    }

    var yearsCount: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year], from: date, to: Date())
        return max(0, components.year ?? 0)
    }

    /// Progress (0...1) through the current cycle toward the next occurrence.
    var cycleProgress: Double {
        let calendar = Calendar.current
        let cycleDays: Double
        switch repeatRule {
        case .yearly: cycleDays = 365
        case .monthly: cycleDays = 30
        case .once:
            return isPast ? 1 : 0
        }
        let remaining = Double(daysRemaining)
        let p = 1 - (remaining / cycleDays)
        return min(max(p, 0), 1)
    }

    /// A friendly upcoming-milestone description (e.g. "1000日まであと12日").
    var milestone: String? {
        guard repeatRule != .once || !isPast else { return nil }
        let since = daysSince
        guard since >= 0 else { return nil }
        let targets = [100, 365, 500, 1000, 2000, 3000, 5000, 10000]
        for t in targets where t > since {
            let diff = t - since
            if diff <= 60 {
                return "\(t)日まであと\(diff)日"
            }
            break
        }
        return nil
    }

    var weekdayName: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ja_JP")
        f.dateFormat = "EEEE"
        return f.string(from: nextOccurrence)
    }
}

// MARK: - Sort

enum SortOption: String, CaseIterable, Identifiable {
    case soonest
    case latest
    case name
    case created

    var id: String { rawValue }

    var label: String {
        switch self {
        case .soonest: return "近い順"
        case .latest: return "遠い順"
        case .name: return "名前順"
        case .created: return "追加順"
        }
    }

    var icon: String {
        switch self {
        case .soonest: return "arrow.up"
        case .latest: return "arrow.down"
        case .name: return "textformat"
        case .created: return "clock"
        }
    }
}

// MARK: - Store

class AnniversaryStore: ObservableObject {
    @Published var items: [Anniversary] = []
    @Published var sortOption: SortOption = .soonest
    @Published var searchText: String = ""
    @Published var categoryFilter: AnniversaryCategory? = nil

    private let key = "anniversaries_v1"

    init() { load() }

    // MARK: CRUD

    func add(_ item: Anniversary) {
        items.append(item)
        save()
    }

    func update(_ item: Anniversary) {
        if let idx = items.firstIndex(where: { $0.id == item.id }) {
            items[idx] = item
            save()
        }
    }

    func delete(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
        save()
    }

    func delete(_ item: Anniversary) {
        items.removeAll { $0.id == item.id }
        save()
    }

    func deleteAll() {
        items.removeAll()
        save()
    }

    func togglePin(_ item: Anniversary) {
        if let idx = items.firstIndex(where: { $0.id == item.id }) {
            items[idx].isPinned.toggle()
            save()
        }
    }

    // MARK: Derived collections

    private func matchesFilters(_ item: Anniversary) -> Bool {
        if let cat = categoryFilter, item.category != cat { return false }
        let q = searchText.trimmingCharacters(in: .whitespaces)
        if !q.isEmpty {
            let haystack = ([item.title, item.note] + item.tags).joined(separator: " ").lowercased()
            if !haystack.contains(q.lowercased()) { return false }
        }
        return true
    }

    private func sortComparator(_ a: Anniversary, _ b: Anniversary) -> Bool {
        switch sortOption {
        case .soonest: return a.daysRemaining < b.daysRemaining
        case .latest: return a.daysRemaining > b.daysRemaining
        case .name: return a.title.localizedCompare(b.title) == .orderedAscending
        case .created: return a.createdAt > b.createdAt
        }
    }

    var filtered: [Anniversary] {
        items.filter(matchesFilters).sorted(by: sortComparator)
    }

    var pinned: [Anniversary] {
        filtered.filter { $0.isPinned }
    }

    var upcoming: [Anniversary] {
        filtered.filter { !$0.isPinned && $0.daysRemaining >= 0 }
    }

    var past: [Anniversary] {
        // one-time events that have already passed
        filtered.filter { !$0.isPinned && $0.daysRemaining < 0 }
    }

    // MARK: Statistics

    var nearest: Anniversary? {
        items.filter { $0.daysRemaining >= 0 }.min { $0.daysRemaining < $1.daysRemaining }
    }

    var todayCount: Int { items.filter { $0.isToday }.count }

    var thisMonthCount: Int {
        let cal = Calendar.current
        let m = cal.component(.month, from: Date())
        return items.filter { cal.component(.month, from: $0.nextOccurrence) == m }.count
    }

    var categoryBreakdown: [(AnniversaryCategory, Int)] {
        AnniversaryCategory.allCases.compactMap { cat in
            let n = items.filter { $0.category == cat }.count
            return n > 0 ? (cat, n) : nil
        }
    }

    // MARK: Persistence

    private func save() {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: key)
        }
        NotificationManager.shared.reschedule(for: items)
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([Anniversary].self, from: data) else { return }
        items = decoded
    }

    // MARK: Export / Import

    func exportData() -> Data? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try? encoder.encode(items)
    }

    @discardableResult
    func importData(_ data: Data, merge: Bool = true) -> Bool {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let imported = try? decoder.decode([Anniversary].self, from: data) else {
            // fall back to default date strategy
            guard let imported2 = try? JSONDecoder().decode([Anniversary].self, from: data) else {
                return false
            }
            applyImport(imported2, merge: merge)
            return true
        }
        applyImport(imported, merge: merge)
        return true
    }

    private func applyImport(_ imported: [Anniversary], merge: Bool) {
        if merge {
            let existingIDs = Set(items.map(\.id))
            items.append(contentsOf: imported.filter { !existingIDs.contains($0.id) })
        } else {
            items = imported
        }
        save()
    }
}
