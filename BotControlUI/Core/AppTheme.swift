//
//  AppTheme.swift
//  BotControlUI
//
//  Created by Edgardo Ramos on 3/20/26.
//

import SwiftUI

enum AppTheme {
    static let shellBackground = Color(nsColor: NSColor(calibratedRed: 0.015, green: 0.025, blue: 0.055, alpha: 1))
    static let sidebarBackground = Color(nsColor: NSColor(calibratedRed: 0.018, green: 0.028, blue: 0.060, alpha: 1))
    static let topbarBackground = Color(nsColor: NSColor(calibratedRed: 0.020, green: 0.030, blue: 0.062, alpha: 0.98))

    static let panelBackground = Color(nsColor: NSColor(calibratedRed: 0.060, green: 0.075, blue: 0.120, alpha: 1))
    static let panelBackgroundSoft = Color(nsColor: NSColor(calibratedRed: 0.075, green: 0.088, blue: 0.135, alpha: 1))

    static let border = Color.white.opacity(0.06)
    static let borderStrong = Color.white.opacity(0.10)

    static let textPrimary = Color.white.opacity(0.50)
    static let textSecondary = Color.white.opacity(0.44)
    static let textMuted = Color.white.opacity(0.28)
    
    static let accent = Color(nsColor: NSColor(calibratedRed: 0.20, green: 0.55, blue: 1.00, alpha: 1))
    
    static let _redAccent = Color(nsColor: NSColor(calibratedRed: 0.98, green: 0.35, blue: 0.34, alpha: 1))
    static let _redAccentSoft = Color(nsColor: NSColor(calibratedRed: 0.28, green: 0.12, blue: 0.14, alpha: 1))
    static let _redAccentBorder = Color(nsColor: NSColor(calibratedRed: 0.60, green: 0.22, blue: 0.24, alpha: 0.9))
    
    // 🔵 Antes "redAccent" → ahora azul (puedes renombrarlo luego si quieres)
    static let redAccent = Color(nsColor: NSColor(calibratedRed: 0.20, green: 0.55, blue: 1.00, alpha: 1))

    // 🔵 versión suave para backgrounds
    static let redAccentSoft = Color(nsColor: NSColor(calibratedRed: 0.08, green: 0.14, blue: 0.24, alpha: 1))

    // 🔵 borde/acento intermedio
    static let redAccentBorder = Color(nsColor: NSColor(calibratedRed: 0.25, green: 0.45, blue: 0.85, alpha: 0.9))

    static let greenStatus = Color(nsColor: NSColor(calibratedRed: 0.13, green: 0.80, blue: 0.38, alpha: 1))
}
