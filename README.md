# CreateApp

SwiftUI で作った iOS アプリをまとめたリポジトリです。現在 2 つのアプリが含まれています。

| アプリ | 概要 | ディレクトリ |
|---|---|---|
| 🎉 **AnniversaryApp** | 記念日を記録・管理するアプリ | [`AnniversaryApp/`](AnniversaryApp) |
| ⛅️ **WeatherApp** | 指定時刻に翌日の天気を通知するアプリ | [`WeatherApp/`](WeatherApp) |

- **言語 / フレームワーク**: Swift 5 / SwiftUI
- **対応 OS**: iOS 17 以降
- **開発環境**: Xcode 16

---

## ⛅️ WeatherApp

設定した時刻に、設定した場所の **翌日の天気** をローカル通知でお知らせするアプリです。

### 主な機能

- 📍 都市名で場所を検索して登録（OpenWeatherMap Geocoding）
- 🌤 明日以降 最大 5 日分の天気（最高 / 最低気温・天気・降水確率）を一覧表示
- 🔔 毎日の指定時刻に「翌日の天気」をローカル通知
- 🔄 アプリ起動時・前面復帰時・バックグラウンド更新時に予報を取得して通知内容を更新

### 使い方

1. [openweathermap.org](https://openweathermap.org/api) で無料登録し、API キーを取得する
2. アプリ右上の歯車から **設定** を開く
3. **API キー** を貼り付ける
4. **場所** をタップし、都市名（例：東京 / Osaka / London）で検索して選択する
5. **「翌日の天気を通知する」** をオンにして通知を許可する
6. **通知する時刻** を設定して完了

> 通知は「次にやってくる指定時刻」に1回予約し、その内容に発火日の翌日の予報を埋め込みます。予報を最新に保つためアプリ起動時などに予約し直すため、1日1回程度アプリを開くと確実です。

詳細は [WeatherApp/README.md](WeatherApp/README.md) を参照してください。

### 構成

| ファイル | 役割 |
|---|---|
| `WeatherApp.swift` | エントリーポイント、バックグラウンド更新の登録 |
| `Models.swift` | データ構造（場所・予報・日次サマリー） |
| `WeatherService.swift` | OpenWeatherMap との通信・集計 |
| `WeatherViewModel.swift` | 予報取得・画面状態・通知予約の中心 |
| `NotificationManager.swift` | 通知の許可とスケジュール |
| `SettingsStore.swift` | 設定の保存（UserDefaults） |
| `ContentView.swift` / `SettingsView.swift` / `LocationSearchView.swift` | 各画面 |

---

## 🎉 AnniversaryApp

記念日を登録し、カテゴリ分けやリマインダー、統計表示、共有などができる記念日管理アプリです。

### 主な機能

- 記念日の登録・編集・削除
- カテゴリによる分類
- リマインダー通知
- 統計表示
- 共有機能

---

## ビルド方法

各アプリのディレクトリにある `.xcodeproj` を Xcode で開き、実行（▶）します。

```sh
# 例：WeatherApp をシミュレータでビルド
cd WeatherApp
xcodebuild -project WeatherApp.xcodeproj -scheme WeatherApp \
  -destination 'platform=iOS Simulator,name=iPhone 17' build
```

## ライセンス

個人開発・学習用のプロジェクトです。
