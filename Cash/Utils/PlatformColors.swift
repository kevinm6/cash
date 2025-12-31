//
//  PlatformColors.swift
//  Cash
//
//  Color definitions for iOS/iPadOS
//

import SwiftUI
import UIKit

extension Color {
    /// Background color for controls
    static var platformControlBackground: Color {
        Color(uiColor: .secondarySystemBackground)
    }

    /// Background color for windows/main views
    static var platformWindowBackground: Color {
        Color(uiColor: .systemBackground)
    }

    /// Separator color
    static var platformSeparator: Color {
        Color(uiColor: .separator)
    }

    /// Background color for text fields
    static var platformTextBackground: Color {
        Color(uiColor: .systemBackground)
    }

    /// Secondary background color
    static var platformSecondaryBackground: Color {
        Color(uiColor: .secondarySystemBackground)
    }

    /// Tertiary background color
    static var platformTertiaryBackground: Color {
        Color(uiColor: .tertiarySystemBackground)
    }
}
