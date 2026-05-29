//
//  ContentView.swift
//  AnniversaryApp
//
//  Created by higurashi on 2026/05/29.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var store = AnniversaryStore()
    @State private var showingAdd = false
    @State private var selectedItem: Anniversary?
    @State private var showingStats = false
    @State private var showingSettings = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0D0D0D").ignoresSafeArea()

                if store.items.isEmpty {
                    EmptyStateView()
                } else {
                    content
                }
            }
            .navigationTitle("記念日")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .searchable(text: $store.searchText, prompt: "タイトル・メモ・タグを検索")
            .toolbar { toolbarContent }
        }
        .preferredColorScheme(.dark)
        .tint(.white)
        .sheet(isPresented: $showingAdd) {
            EditView(store: store)
        }
        .sheet(item: $selectedItem) { item in
            DetailView(item: item, store: store)
        }
        .sheet(isPresented: $showingStats) {
            StatisticsView(store: store)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(store: store)
        }
        .onAppear {
            NotificationManager.shared.requestAuthorization()
        }
    }

    // MARK: - Main content

    private var content: some View {
        ScrollView {
            categoryChips

            LazyVStack(spacing: 16) {
                section(title: "ピン留め", icon: "pin.fill", items: store.pinned)
                section(title: "これから", icon: "calendar", items: store.upcoming)
                section(title: "過ぎた記念日", icon: "clock.arrow.circlepath", items: store.past)

                if store.filtered.isEmpty {
                    Text("該当する記念日がありません")
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.4))
                        .padding(.top, 60)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 4)
            .padding(.bottom, 32)
            .animation(.easeInOut(duration: 0.25), value: store.sortOption)
        }
    }

    @ViewBuilder
    private func section(title: String, icon: String, items: [Anniversary]) -> some View {
        if !items.isEmpty {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                Text("\(items.count)")
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(.white.opacity(0.45))
            .padding(.top, 12)

            ForEach(items) { item in
                Button {
                    Haptics.tap()
                    selectedItem = item
                } label: {
                    AnniversaryCard(item: item)
                }
                .buttonStyle(.plain)
                .contextMenu {
                    Button {
                        store.togglePin(item)
                        Haptics.selection()
                    } label: {
                        Label(item.isPinned ? "ピンを外す" : "ピン留め",
                              systemImage: item.isPinned ? "pin.slash" : "pin")
                    }
                    Button(role: .destructive) {
                        store.delete(item)
                    } label: {
                        Label("削除", systemImage: "trash")
                    }
                }
            }
        }
    }

    // MARK: - Category chips

    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip(label: "すべて", icon: "square.grid.2x2",
                     selected: store.categoryFilter == nil) {
                    store.categoryFilter = nil
                }
                ForEach(AnniversaryCategory.allCases) { cat in
                    if store.items.contains(where: { $0.category == cat }) {
                        chip(label: cat.label, icon: cat.icon,
                             selected: store.categoryFilter == cat,
                             color: Color(hex: cat.defaultColor)) {
                            store.categoryFilter = store.categoryFilter == cat ? nil : cat
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
    }

    private func chip(label: String, icon: String, selected: Bool,
                      color: Color = .white, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.selection()
            action()
        } label: {
            HStack(spacing: 5) {
                Image(systemName: icon).font(.system(size: 11, weight: .semibold))
                Text(label).font(.system(size: 13, weight: .medium))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(selected ? color.opacity(0.9) : Color.white.opacity(0.08))
            .foregroundColor(selected ? .black : .white.opacity(0.8))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Menu {
                Picker("並び替え", selection: $store.sortOption) {
                    ForEach(SortOption.allCases) { opt in
                        Label(opt.label, systemImage: opt.icon).tag(opt)
                    }
                }
                Divider()
                Button {
                    showingStats = true
                } label: {
                    Label("統計", systemImage: "chart.bar.fill")
                }
                Button {
                    showingSettings = true
                } label: {
                    Label("設定", systemImage: "gearshape.fill")
                }
            } label: {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                Haptics.tap()
                showingAdd = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
    }
}

// MARK: - Empty State

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 64))
                .foregroundColor(.white.opacity(0.25))
            Text("記念日を追加しよう")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white.opacity(0.5))
            Text("右上の＋ボタンから\n大切な日を登録できます")
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.3))
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - Card

struct AnniversaryCard: View {
    let item: Anniversary

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Background
            Group {
                if let data = item.imageData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                } else {
                    LinearGradient(
                        colors: [Color(hex: item.colorHex).opacity(0.8),
                                 Color(hex: item.colorHex).opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
            }
            .frame(height: 200)
            .clipped()

            // Gradient overlay
            LinearGradient(
                colors: [.clear, .black.opacity(0.75)],
                startPoint: .top,
                endPoint: .bottom
            )

            // Top-left: category + pin
            VStack {
                HStack(spacing: 6) {
                    Label(item.category.label, systemImage: item.category.icon)
                        .font(.system(size: 11, weight: .semibold))
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                    if item.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.system(size: 11, weight: .semibold))
                            .padding(6)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                    Spacer()
                }
                Spacer()
            }
            .foregroundColor(.white)
            .padding(14)

            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .lastTextBaseline, spacing: 6) {
                    Text("\(abs(item.daysRemaining))")
                        .font(.system(size: 52, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                    Text("日")
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.85))
                        .padding(.bottom, 6)
                    Spacer()
                    BadgeView(item: item)
                }
                Text(item.title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                HStack(spacing: 8) {
                    Text(item.date, style: .date)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.6))
                    if let m = item.milestone {
                        Text("• \(m)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.yellow.opacity(0.9))
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 18)
        }
        .frame(height: 200)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color(hex: item.colorHex).opacity(0.3), radius: 12, x: 0, y: 6)
    }
}

struct BadgeView: View {
    let item: Anniversary

    var body: some View {
        Group {
            if item.daysRemaining == 0 {
                Text("TODAY🎉")
                    .font(.system(size: 12, weight: .bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(.yellow)
                    .foregroundColor(.black)
                    .clipShape(Capsule())
            } else {
                Text(item.daysRemaining > 0 ? "あと" : "\(item.yearsCount)周年")
                    .font(.system(size: 11, weight: .semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color(hex: item.colorHex).opacity(0.9))
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }
        }
    }
}
