//
//  Models.swift
//  WeatherApp
//
//  天気アプリで使うデータ構造をまとめたファイル。
//

import Foundation

// MARK: - 保存する場所

/// ユーザーが選んだ通知対象の場所。UserDefaults に保存できるよう Codable にしている。
struct SavedLocation: Codable, Equatable {
    var name: String        // 表示名（例: 東京都, Tokyo）
    var latitude: Double
    var longitude: Double
}

// MARK: - ジオコーディング（都市名検索）の結果

/// OpenWeatherMap の Geocoding API のレスポンス 1 件分。
struct GeoResult: Decodable, Identifiable {
    let name: String
    let localNames: [String: String]?
    let lat: Double
    let lon: Double
    let country: String
    let state: String?

    // 同じ都市名でも緯度経度で区別できるよう id を作る
    var id: String { "\(lat),\(lon),\(name)" }

    enum CodingKeys: String, CodingKey {
        case name, lat, lon, country, state
        case localNames = "local_names"
    }

    /// 画面に表示する名前。日本語名があれば優先する。
    var displayName: String {
        let primary = localNames?["ja"] ?? name
        if let state, !state.isEmpty {
            return "\(primary)（\(state), \(country)）"
        }
        return "\(primary)（\(country)）"
    }

    /// 保存用の場所に変換する。
    func toSavedLocation() -> SavedLocation {
        SavedLocation(name: localNames?["ja"] ?? name, latitude: lat, longitude: lon)
    }
}

// MARK: - 天気予報 API のレスポンス

/// OpenWeatherMap の 5 day / 3 hour forecast API のトップレベル。
struct ForecastResponse: Decodable {
    let list: [ForecastEntry]
}

/// 3 時間ごとの予報 1 件分。
struct ForecastEntry: Decodable {
    let dt: TimeInterval
    let main: MainInfo
    let weather: [WeatherInfo]
    let pop: Double?        // 降水確率 0.0〜1.0

    struct MainInfo: Decodable {
        let temp: Double
        let tempMin: Double
        let tempMax: Double

        enum CodingKeys: String, CodingKey {
            case temp
            case tempMin = "temp_min"
            case tempMax = "temp_max"
        }
    }

    struct WeatherInfo: Decodable {
        let id: Int
        let main: String
        let description: String
        let icon: String
    }

    /// 予報の対象日時。
    var date: Date { Date(timeIntervalSince1970: dt) }
}

// MARK: - 1 日分にまとめた予報

/// 3 時間ごとの予報を「その日 1 日分」に集計した結果。画面表示と通知の両方で使う。
struct DailyForecast: Identifiable {
    let id = UUID()
    let date: Date
    let minTemp: Double
    let maxTemp: Double
    let description: String   // 日本語の天気説明（例: 曇りがち）
    let symbolName: String    // SF Symbol 名
    let pop: Double           // 降水確率 0.0〜1.0

    /// 通知本文などに使う、温度を整数の文字列にしたもの。
    var minTempText: String { "\(Int(minTemp.rounded()))℃" }
    var maxTempText: String { "\(Int(maxTemp.rounded()))℃" }
    var popText: String { "\(Int((pop * 100).rounded()))%" }
}
