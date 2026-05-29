//
//  StatisticsView.swift
//  AnniversaryApp
//
//  Overview & breakdown of all anniversaries.
//

import SwiftUI

struct StatisticsView: View {
    @ObservedObject var store: AnniversaryStore
    @Environment(\.dismiss) private var dismiss

    private var totalDaysTracked: Int {
        store.items.map { max(0, $0.daysSince) }.reduce(0, +)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0D0D0D").ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        summaryGrid

                        if let n = store.nearest {
                            nextUpCard(n)
                        }

                        if !store.categoryBreakdown.isEmpty {
                            breakdownSection
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("統計")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") { dismiss() }.foregroundColor(.white)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var summaryGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
            statCard("登録数", "\(store.items.count)", "list.bullet", "4ECDC4")
            statCard("今日", "\(store.todayCount)", "party.popper.fill", "FFCC02")
            statCard("今月", "\(store.thisMonthCount)", "calendar", "FF8E53")
            statCard("ピン留め", "\(store.items.filter { $0.isPinned }.count)", "pin.fill", "F7AEF8")
        }
    }

    private func statCard(_ label: String, _ value: String, _ icon: String, _ hex: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(Color(hex: hex))
            Text(value)
                .font(.system(size: 30, weight: .black, design: .rounded))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func nextUpCard(_ item: Anniversary) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("次の記念日")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white.opacity(0.5))
            HStack {
                Label(item.title, systemImage: item.category.icon)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
                Text(item.daysRemaining == 0 ? "今日" : "あと\(item.daysRemaining)日")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: item.colorHex))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var breakdownSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("カテゴリー別")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white.opacity(0.5))

            let maxCount = store.categoryBreakdown.map(\.1).max() ?? 1
            ForEach(store.categoryBreakdown, id: \.0) { cat, count in
                HStack(spacing: 12) {
                    Image(systemName: cat.icon)
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: cat.defaultColor))
                        .frame(width: 22)
                    Text(cat.label)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.85))
                        .frame(width: 56, alignment: .leading)
                    GeometryReader { geo in
                        Capsule()
                            .fill(Color(hex: cat.defaultColor))
                            .frame(width: geo.size.width * CGFloat(count) / CGFloat(maxCount))
                    }
                    .frame(height: 10)
                    Text("\(count)")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(width: 24, alignment: .trailing)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
