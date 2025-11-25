//
//  AppSettings.swift
//  Cash
//
//  Created by Michele Broggi on 25/11/25.
//

import Foundation
import SwiftUI

enum AppTheme: String, CaseIterable, Identifiable {
    case system = "system"
    case light = "light"
    case dark = "dark"
    
    var id: String { rawValue }
    
    var localizedName: String {
        switch self {
        case .system:
            return String(localized: "System")
        case .light:
            return String(localized: "Light")
        case .dark:
            return String(localized: "Dark")
        }
    }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
    
    var iconName: String {
        switch self {
        case .system:
            return "circle.lefthalf.filled"
        case .light:
            return "sun.max.fill"
        case .dark:
            return "moon.fill"
        }
    }
}

enum AppLanguage: String, CaseIterable, Identifiable {
    case system = "system"
    case english = "en"
    case italian = "it"
    
    var id: String { rawValue }
    
    var localizedName: String {
        switch self {
        case .system:
            return String(localized: "System")
        case .english:
            return "English"
        case .italian:
            return "Italiano"
        }
    }
    
    var iconName: String {
        switch self {
        case .system:
            return "globe"
        case .english:
            return "flag.fill"
        case .italian:
            return "flag.fill"
        }
    }
}

@Observable
final class AppSettings {
    static let shared = AppSettings()
    
    private let themeKey = "appTheme"
    private let languageKey = "appLanguage"
    
    var theme: AppTheme {
        didSet {
            UserDefaults.standard.set(theme.rawValue, forKey: themeKey)
        }
    }
    
    var language: AppLanguage {
        didSet {
            UserDefaults.standard.set(language.rawValue, forKey: languageKey)
            applyLanguage()
        }
    }
    
    private init() {
        if let themeRaw = UserDefaults.standard.string(forKey: themeKey),
           let savedTheme = AppTheme(rawValue: themeRaw) {
            self.theme = savedTheme
        } else {
            self.theme = .system
        }
        
        if let langRaw = UserDefaults.standard.string(forKey: languageKey),
           let savedLang = AppLanguage(rawValue: langRaw) {
            self.language = savedLang
        } else {
            self.language = .system
        }
    }
    
    private func applyLanguage() {
        if language == .system {
            UserDefaults.standard.removeObject(forKey: "AppleLanguages")
        } else {
            UserDefaults.standard.set([language.rawValue], forKey: "AppleLanguages")
        }
    }
}
