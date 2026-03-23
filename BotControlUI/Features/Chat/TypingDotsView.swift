//
//  Untitled.swift
//  BotControlUI
//
//  Created by Edgardo Ramos on 3/21/26.
//

import SwiftUI

struct TypingDotsView: View {
    @State private var phase = 0

    var body: some View {
        HStack(spacing: 6) {
            dot(index: 0)
            dot(index: 1)
            dot(index: 2)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.9).repeatForever()) {
                phase = 3
            }
        }
    }

    private func dot(index: Int) -> some View {
        Circle()
            .fill(AppTheme.textSecondary)
            .frame(width: 8, height: 8)
            .scaleEffect(scale(for: index))
            .opacity(opacity(for: index))
            .animation(
                .easeInOut(duration: 0.6)
                .repeatForever()
                .delay(Double(index) * 0.18),
                value: phase
            )
    }

    private func scale(for index: Int) -> CGFloat {
        phase > index ? 1.0 : 0.72
    }

    private func opacity(for index: Int) -> Double {
        phase > index ? 1.0 : 0.35
    }
}
