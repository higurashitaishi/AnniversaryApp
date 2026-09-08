//
//  WeatherApp.swift
//  WeatherApp
//
//  アプリのエントリーポイント。設定の共有と、バックグラウンド更新の登録を行う。
//

import SwiftUI
import BackgroundTasks

@main
struct WeatherApp: App {
    /// バックグラウンド更新タスクの識別子（Info.plist の登録名と一致させる）。
    static let refreshTaskID = "com.Taishi.WeatherApp.refresh"

    @StateObject private var settings = SettingsStore()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView(settings: settings)
                .environmentObject(settings)
        }
        .onChange(of: scenePhase) { _, phase in
            // バックグラウンドに入るとき、次回の自動更新を予約しておく
            if phase == .background {
                scheduleAppRefresh()
            }
        }
        // 端末がアプリを起こしたときに最新予報を取得して通知を入れ直す
        .backgroundTask(.appRefresh(Self.refreshTaskID)) {
            await runBackgroundRefresh()
            await scheduleAppRefreshAsync()
        }
    }

    /// バックグラウンドで予報を取り直し、通知を更新する。
    @MainActor
    private func runBackgroundRefresh() async {
        let settings = SettingsStore()
        guard settings.isReady, settings.notificationsEnabled else { return }
        let viewModel = WeatherViewModel(settings: settings)
        await viewModel.refresh()
    }

    /// 次回のバックグラウンド更新を OS に依頼する。
    private func scheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: Self.refreshTaskID)
        // 最短でも数時間後に実行（実際の実行タイミングは OS が判断する）
        request.earliestBeginDate = Date(timeIntervalSinceNow: 4 * 60 * 60)
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("バックグラウンド更新の予約に失敗しました: \(error)")
        }
    }

    private func scheduleAppRefreshAsync() async {
        scheduleAppRefresh()
    }
}
