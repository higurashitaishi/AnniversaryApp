//
//  SettingsView.swift
//  AnniversaryApp
//
//  Backup / restore, notifications, and about.
//

import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @ObservedObject var store: AnniversaryStore
    @Environment(\.dismiss) private var dismiss

    @State private var showingExport = false
    @State private var exportURL: URL?
    @State private var showingImporter = false
    @State private var notifStatusText = "未確認"
    @State private var alert: AlertItem?

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0D0D0D").ignoresSafeArea()
                List {
                    notificationsSection
                    backupSection
                    dataSection
                    aboutSection
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") { dismiss() }.foregroundColor(.white)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear(perform: refreshNotifStatus)
        .sheet(isPresented: $showingExport) {
            if let url = exportURL {
                ActivityView(items: [url])
            }
        }
        .fileImporter(isPresented: $showingImporter,
                      allowedContentTypes: [.json],
                      allowsMultipleSelection: false) { result in
            handleImport(result)
        }
        .alert(item: $alert) { a in
            Alert(title: Text(a.title), message: Text(a.message), dismissButton: .default(Text("OK")))
        }
    }

    // MARK: - Sections

    private var notificationsSection: some View {
        Section {
            HStack {
                Label("通知の状態", systemImage: "bell.fill")
                Spacer()
                Text(notifStatusText).foregroundColor(.white.opacity(0.5))
            }
            Button {
                NotificationManager.shared.requestAuthorization { _ in refreshNotifStatus() }
            } label: {
                Label("通知を許可する", systemImage: "checkmark.seal")
            }
        } header: {
            Text("通知")
        } footer: {
            Text("各記念日の編集画面でリマインドのオン／オフと通知日を設定できます。")
        }
        .listRowBackground(Color.white.opacity(0.06))
    }

    private var backupSection: some View {
        Section {
            Button {
                exportBackup()
            } label: {
                Label("バックアップを書き出す", systemImage: "square.and.arrow.up")
            }
            Button {
                showingImporter = true
            } label: {
                Label("バックアップを読み込む", systemImage: "square.and.arrow.down")
            }
        } header: {
            Text("バックアップ")
        } footer: {
            Text("JSON 形式で全データを書き出し／読み込みできます。読み込み時は重複しない項目のみ追加されます。")
        }
        .listRowBackground(Color.white.opacity(0.06))
    }

    private var dataSection: some View {
        Section {
            if store.items.isEmpty {
                Button {
                    for s in SampleData.make() { store.add(s) }
                    alert = AlertItem(title: "追加しました", message: "サンプルの記念日を追加しました。")
                } label: {
                    Label("サンプルデータを追加", systemImage: "wand.and.stars")
                }
            }
            Button(role: .destructive) {
                deleteAll()
            } label: {
                Label("すべて削除", systemImage: "trash")
            }
        } header: {
            Text("データ")
        }
        .listRowBackground(Color.white.opacity(0.06))
    }

    private var aboutSection: some View {
        Section {
            HStack {
                Label("バージョン", systemImage: "info.circle")
                Spacer()
                Text(appVersion).foregroundColor(.white.opacity(0.5))
            }
            HStack {
                Label("登録数", systemImage: "number")
                Spacer()
                Text("\(store.items.count)").foregroundColor(.white.opacity(0.5))
            }
        } header: {
            Text("このアプリについて")
        }
        .listRowBackground(Color.white.opacity(0.06))
    }

    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        return "v\(v)"
    }

    // MARK: - Actions

    private func refreshNotifStatus() {
        NotificationManager.shared.authorizationStatus { status in
            switch status {
            case .authorized: notifStatusText = "許可済み"
            case .denied: notifStatusText = "拒否"
            case .notDetermined: notifStatusText = "未設定"
            case .provisional: notifStatusText = "仮許可"
            case .ephemeral: notifStatusText = "一時的"
            @unknown default: notifStatusText = "不明"
            }
        }
    }

    private func exportBackup() {
        guard let data = store.exportData() else {
            alert = AlertItem(title: "失敗", message: "書き出しに失敗しました。")
            return
        }
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("anniversaries-backup.json")
        do {
            try data.write(to: url)
            exportURL = url
            showingExport = true
        } catch {
            alert = AlertItem(title: "失敗", message: error.localizedDescription)
        }
    }

    private func handleImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            let needsStop = url.startAccessingSecurityScopedResource()
            defer { if needsStop { url.stopAccessingSecurityScopedResource() } }
            do {
                let data = try Data(contentsOf: url)
                if store.importData(data, merge: true) {
                    alert = AlertItem(title: "読み込み完了", message: "バックアップを取り込みました。")
                } else {
                    alert = AlertItem(title: "失敗", message: "ファイル形式が正しくありません。")
                }
            } catch {
                alert = AlertItem(title: "失敗", message: error.localizedDescription)
            }
        case .failure(let error):
            alert = AlertItem(title: "失敗", message: error.localizedDescription)
        }
    }

    private func deleteAll() {
        store.deleteAll()
        alert = AlertItem(title: "削除しました", message: "すべての記念日を削除しました。")
    }
}

struct AlertItem: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}
