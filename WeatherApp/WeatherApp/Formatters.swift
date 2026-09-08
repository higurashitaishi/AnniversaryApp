//
//  Formatters.swift
//  WeatherApp
//
//  日付・時刻の表示用フォーマッタをまとめる。
//

import Foundation

enum DateFormatters {
    /// 「6月10日(火)」のような日付表示。
    static let dayWithWeekday: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ja_JP")
        f.dateFormat = "M月d日(E)"
        return f
    }()

    /// 「7:00」のような時刻表示。
    static let time: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ja_JP")
        f.dateFormat = "H:mm"
        return f
    }()

    /// 「6月9日 21:30 更新」用。
    static let updated: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ja_JP")
        f.dateFormat = "M月d日 H:mm"
        return f
    }()
}
