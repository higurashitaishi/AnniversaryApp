//
//  WeatherService.swift
//  WeatherApp
//
//  OpenWeatherMap と通信して、都市検索と天気予報の取得を行う。
//

import Foundation

/// 天気取得に関するエラー。ユーザーに見せられる日本語メッセージを持つ。
enum WeatherError: LocalizedError {
    case missingAPIKey
    case missingLocation
    case invalidResponse
    case http(Int)
    case noForecast

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "APIキーが設定されていません。設定画面で OpenWeatherMap のAPIキーを入力してください。"
        case .missingLocation:
            return "場所が設定されていません。設定画面で場所を選んでください。"
        case .invalidResponse:
            return "サーバーからの応答を読み取れませんでした。"
        case .http(let code):
            if code == 401 {
                return "APIキーが正しくないようです（401）。設定を確認してください。"
            }
            return "通信エラーが発生しました（コード: \(code)）。"
        case .noForecast:
            return "指定した日の天気予報が取得できませんでした。"
        }
    }
}

/// OpenWeatherMap のクライアント。状態を持たない値型。
struct WeatherService {
    let apiKey: String

    private static let session = URLSession.shared

    // MARK: - 都市名で検索（Geocoding API）

    func search(city: String) async throws -> [GeoResult] {
        let trimmed = city.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !apiKey.isEmpty else { throw WeatherError.missingAPIKey }
        guard !trimmed.isEmpty else { return [] }

        var comps = URLComponents(string: "https://api.openweathermap.org/geo/1.0/direct")!
        comps.queryItems = [
            URLQueryItem(name: "q", value: trimmed),
            URLQueryItem(name: "limit", value: "5"),
            URLQueryItem(name: "appid", value: apiKey),
        ]

        let (data, response) = try await Self.session.data(from: comps.url!)
        try Self.checkHTTP(response)
        return try JSONDecoder().decode([GeoResult].self, from: data)
    }

    // MARK: - 5 日分の予報を取得（forecast API）

    func fetchForecast(lat: Double, lon: Double) async throws -> [ForecastEntry] {
        guard !apiKey.isEmpty else { throw WeatherError.missingAPIKey }

        var comps = URLComponents(string: "https://api.openweathermap.org/data/2.5/forecast")!
        comps.queryItems = [
            URLQueryItem(name: "lat", value: String(lat)),
            URLQueryItem(name: "lon", value: String(lon)),
            URLQueryItem(name: "units", value: "metric"),
            URLQueryItem(name: "lang", value: "ja"),
            URLQueryItem(name: "appid", value: apiKey),
        ]

        let (data, response) = try await Self.session.data(from: comps.url!)
        try Self.checkHTTP(response)
        let decoded = try JSONDecoder().decode(ForecastResponse.self, from: data)
        return decoded.list
    }

    // MARK: - 集計

    /// 指定したカレンダー日 1 日分の予報をまとめる。該当データが無ければ nil。
    func dailyForecast(for day: Date,
                       from entries: [ForecastEntry],
                       calendar: Calendar = .current) -> DailyForecast? {
        let dayEntries = entries.filter { calendar.isDate($0.date, inSameDayAs: day) }
        guard !dayEntries.isEmpty else { return nil }

        let minTemp = dayEntries.map(\.main.tempMin).min() ?? 0
        let maxTemp = dayEntries.map(\.main.tempMax).max() ?? 0
        let pop = dayEntries.compactMap(\.pop).max() ?? 0

        // 代表的な天気は、正午にいちばん近い時間帯のものを使う。
        let representative = dayEntries.min { lhs, rhs in
            let lh = abs(calendar.component(.hour, from: lhs.date) - 12)
            let rh = abs(calendar.component(.hour, from: rhs.date) - 12)
            return lh < rh
        }
        let weather = representative?.weather.first
        let description = weather?.description ?? "—"
        let symbol = Self.symbolName(conditionID: weather?.id ?? 800, icon: weather?.icon ?? "01d")

        return DailyForecast(date: day,
                             minTemp: minTemp,
                             maxTemp: maxTemp,
                             description: description,
                             symbolName: symbol,
                             pop: pop)
    }

    // MARK: - ヘルパー

    private static func checkHTTP(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else {
            throw WeatherError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            throw WeatherError.http(http.statusCode)
        }
    }

    /// OpenWeatherMap の天気IDとアイコンコードを SF Symbol 名に変換する。
    /// 参考: https://openweathermap.org/weather-conditions
    static func symbolName(conditionID id: Int, icon: String) -> String {
        let isNight = icon.hasSuffix("n")
        switch id {
        case 200..<300:                       // 雷雨
            return "cloud.bolt.rain.fill"
        case 300..<400:                       // 霧雨
            return "cloud.drizzle.fill"
        case 511:                             // 着氷性の雨
            return "cloud.sleet.fill"
        case 500..<600:                       // 雨
            return "cloud.rain.fill"
        case 600..<700:                       // 雪
            return "cloud.snow.fill"
        case 700..<800:                       // 霧・もや など
            return "cloud.fog.fill"
        case 800:                             // 快晴
            return isNight ? "moon.stars.fill" : "sun.max.fill"
        case 801:                             // 少し雲あり
            return isNight ? "cloud.moon.fill" : "cloud.sun.fill"
        case 802...804:                       // 曇り
            return "cloud.fill"
        default:
            return "cloud.fill"
        }
    }
}
