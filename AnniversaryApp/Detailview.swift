//
//  Detailview.swift
//  AnniversaryApp
//
//  Created by higurashi on 2026/05/29.
//

import SwiftUI
import Combine

struct DetailView: View {
    let item: Anniversary
    let store: AnniversaryStore
    @Environment(\.dismiss) private var dismiss
    @State private var showingEdit = false
    @State private var showingShare = false
    @State private var shareImage: UIImage?
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var now = Date()

    private var secondsRemaining: Int {
        let target = Calendar.current.startOfDay(for: item.nextOccurrence).addingTimeInterval(86400)
        return max(0, Int(target.timeIntervalSince(now)))
    }

    private var hh: Int { secondsRemaining / 3600 }
    private var mm: Int { (secondsRemaining % 3600) / 60 }
    private var ss: Int { secondsRemaining % 60 }

    var body: some View {
        ZStack {
            backgroundLayer
            Color.black.opacity(0.45).ignoresSafeArea()

            VStack(spacing: 0) {
                topBar

                Spacer()

                VStack(spacing: 8) {
                    Label(item.category.label, systemImage: item.category.icon)
                        .font(.system(size: 13, weight: .semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .foregroundColor(.white)

                    Text(item.title)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    Text(item.date.longJapanese)
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.65))
                }
                .padding(.horizontal, 32)

                Spacer().frame(height: 40)

                // Main countdown
                if item.daysRemaining == 0 {
                    todayView
                } else if item.daysRemaining > 0 {
                    countdownView
                } else {
                    anniversaryView
                }

                Spacer()

                if let m = item.milestone {
                    Text("🎯 \(m)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.yellow)
                        .padding(.bottom, 8)
                }

                if !item.note.isEmpty {
                    Text(item.note)
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .padding(.bottom, 8)
                }

                if !item.tags.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(item.tags, id: \.self) { tag in
                            Text("#\(tag)")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                    .padding(.bottom, 12)
                }

                yearSection
                    .padding(.bottom, 48)
            }

            // Confetti on the big day
            if item.daysRemaining == 0 {
                ConfettiView()
                    .allowsHitTesting(false)
                    .ignoresSafeArea()
            }
        }
        .ignoresSafeArea()
        .onReceive(timer) { _ in now = Date() }
        .sheet(isPresented: $showingEdit) {
            EditView(store: store, existing: item)
        }
        .sheet(isPresented: $showingShare) {
            if let img = shareImage {
                ActivityView(items: [img])
            }
        }
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack(spacing: 12) {
            circleButton("chevron.down") { dismiss() }
            Spacer()
            circleButton("square.and.arrow.up") { shareCard() }
            circleButton("pencil") { showingEdit = true }
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
    }

    private func circleButton(_ icon: String, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .padding(12)
                .background(.white.opacity(0.15))
                .clipShape(Circle())
        }
    }

    // MARK: - Share

    @MainActor
    private func shareCard() {
        let card = ShareCard(item: item)
        shareImage = card.snapshot(size: CGSize(width: 360, height: 360))
        showingShare = true
    }

    // MARK: - Sub-views

    @ViewBuilder
    var backgroundLayer: some View {
        if let data = item.imageData, let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
        } else {
            LinearGradient(
                colors: [Color(hex: item.colorHex),
                         Color(hex: item.colorHex).opacity(0.4),
                         .black],
                startPoint: .topLeading,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
    }

    var countdownView: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.15), lineWidth: 8)
                Circle()
                    .trim(from: 0, to: item.cycleProgress)
                    .stroke(Color.white, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 0) {
                    Text("\(item.daysRemaining)")
                        .font(.system(size: 72, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                    Text("日後")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .frame(width: 220, height: 220)

            Spacer().frame(height: 24)

            HStack(spacing: 0) {
                timeUnit(value: hh, label: "時間")
                timeSep()
                timeUnit(value: mm, label: "分")
                timeSep()
                timeUnit(value: ss, label: "秒")
            }
        }
    }

    var todayView: some View {
        VStack(spacing: 16) {
            Text("🎉")
                .font(.system(size: 72))
            Text("今日です！")
                .font(.system(size: 36, weight: .black, design: .rounded))
                .foregroundColor(.yellow)
        }
    }

    var anniversaryView: some View {
        VStack(spacing: 6) {
            Text("\(item.yearsCount)")
                .font(.system(size: 96, weight: .black, design: .rounded))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.4), radius: 8)
            Text("周年 🎊")
                .font(.system(size: 24, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.85))
            Text("経過日数: \(item.daysSince)日")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.5))
                .padding(.top, 8)
        }
    }

    var yearSection: some View {
        HStack(spacing: 24) {
            statPill(label: "経過", value: "\(item.daysSince)日")
            if item.yearsCount > 0 {
                statPill(label: "年数", value: "\(item.yearsCount)年")
            }
            statPill(label: "次回", value: nextLabel)
        }
        .padding(.horizontal, 24)
    }

    var nextLabel: String {
        let days = item.daysRemaining
        if days == 0 { return "今日" }
        if days > 0 { return "\(days)日後" }
        return "\(abs(days))日前"
    }

    func statPill(label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(.white.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    func timeUnit(value: Int, label: String) -> some View {
        VStack(spacing: 2) {
            Text(String(format: "%02d", value))
                .font(.system(size: 38, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(width: 72)
        .padding(.vertical, 10)
        .background(.white.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    func timeSep() -> some View {
        Text(":")
            .font(.system(size: 30, weight: .bold))
            .foregroundColor(.white.opacity(0.5))
            .padding(.bottom, 14)
            .padding(.horizontal, 4)
    }
}

// MARK: - Shareable card (rendered to an image)

struct ShareCard: View {
    let item: Anniversary

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: item.colorHex),
                         Color(hex: item.colorHex).opacity(0.5),
                         .black],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            if let data = item.imageData, let ui = UIImage(data: data) {
                Image(uiImage: ui).resizable().scaledToFill()
                LinearGradient(colors: [.clear, .black.opacity(0.7)],
                               startPoint: .top, endPoint: .bottom)
            }

            VStack(spacing: 10) {
                Image(systemName: item.category.icon)
                    .font(.system(size: 28))
                    .foregroundColor(.white.opacity(0.9))
                Text(item.title)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                if item.daysRemaining > 0 {
                    Text("あと \(item.daysRemaining) 日")
                        .font(.system(size: 40, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                } else if item.daysRemaining == 0 {
                    Text("今日です 🎉")
                        .font(.system(size: 36, weight: .black, design: .rounded))
                        .foregroundColor(.yellow)
                } else {
                    Text("\(item.yearsCount) 周年")
                        .font(.system(size: 40, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                }
                Text(item.date.longJapanese)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.75))
            }
            .padding(28)
        }
        .frame(width: 360, height: 360)
    }
}
