//
//  ConfettiView.swift
//  AnniversaryApp
//
//  A lightweight SwiftUI confetti burst used on the big day.
//

import SwiftUI

struct ConfettiView: View {
    private let colors: [Color] = [
        .red, .orange, .yellow, .green, .blue, .purple, .pink, .mint
    ]
    @State private var animate = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(0..<80, id: \.self) { i in
                    ConfettiPiece(
                        color: colors[i % colors.count],
                        startX: CGFloat.random(in: 0...geo.size.width),
                        endY: geo.size.height + 40,
                        delay: Double.random(in: 0...1.2),
                        duration: Double.random(in: 1.8...3.2),
                        size: CGFloat.random(in: 6...12),
                        spin: Double.random(in: 180...720)
                    )
                }
            }
        }
    }
}

private struct ConfettiPiece: View {
    let color: Color
    let startX: CGFloat
    let endY: CGFloat
    let delay: Double
    let duration: Double
    let size: CGFloat
    let spin: Double

    @State private var falling = false

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(color)
            .frame(width: size, height: size * 0.6)
            .position(x: startX + (falling ? CGFloat.random(in: -40...40) : 0),
                      y: falling ? endY : -40)
            .rotationEffect(.degrees(falling ? spin : 0))
            .opacity(falling ? 0 : 1)
            .onAppear {
                withAnimation(.easeIn(duration: duration).delay(delay).repeatForever(autoreverses: false)) {
                    falling = true
                }
            }
    }
}
