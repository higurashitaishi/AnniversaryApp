# WeatherApp（お天気通知アプリ）

設定した時刻に、設定した場所の **翌日の天気** をローカル通知でお知らせする iOS アプリです。

## できること

- 都市名で場所を検索して登録（OpenWeatherMap Geocoding）
- 明日以降 最大5日分の天気（最高/最低気温・天気・降水確率）を表示
- 毎日の指定時刻に「翌日の天気」を通知
- アプリ起動時・前面復帰時・バックグラウンド更新時に予報を取得して通知内容を更新

## 使い方

1. **APIキーを取得**
   [openweathermap.org](https://openweathermap.org/api) で無料登録し、API キーを発行します。
   （発行直後は有効化まで数十分かかることがあります）
2. アプリ右上の歯車から **設定** を開く
3. **APIキー** を貼り付ける
4. **場所** をタップし、都市名（例：東京 / Osaka / London）で検索して選択
5. **「翌日の天気を通知する」** をオンにし、通知を許可する
6. **通知する時刻** を設定して完了

## 通知の仕組みと制限

- 通知は「次にやってくる指定時刻」に1回だけ予約し、その内容に**発火日の翌日**の予報を埋め込みます。
- 予報を最新に保つため、アプリ起動・前面復帰時、および iOS のバックグラウンド更新（`BGAppRefreshTask`）のたびに取得して予約し直します。
- バックグラウンド更新の実行タイミングは iOS が判断するため、長期間アプリを一度も開かないと通知が止まる場合があります。1日1回程度アプリを開くと確実です。

## ビルド方法

この Mac は `xcode-select` が Command Line Tools を指しているため、コマンドラインからビルドする場合は Xcode 本体を明示します。

```sh
cd WeatherApp
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcodebuild -project WeatherApp.xcodeproj -scheme WeatherApp \
  -destination 'platform=iOS Simulator,name=iPhone 17' build
```

Xcode で開く場合は `WeatherApp.xcodeproj` をダブルクリックして実行（▶）するだけです。

## 構成

| ファイル | 役割 |
|---|---|
| `WeatherApp.swift` | エントリーポイント、バックグラウンド更新の登録 |
| `Models.swift` | データ構造（場所・予報・日次サマリー） |
| `WeatherService.swift` | OpenWeatherMap との通信・集計 |
| `WeatherViewModel.swift` | 予報取得・画面状態・通知予約の中心 |
| `NotificationManager.swift` | 通知の許可とスケジュール |
| `SettingsStore.swift` | 設定の保存（UserDefaults） |
| `ContentView.swift` | メイン画面 |
| `SettingsView.swift` | 設定画面 |
| `LocationSearchView.swift` | 場所検索画面 |
| `Formatters.swift` | 日付・時刻の表示整形 |
