//
//  Constants.swift
//  WTCChatApp
//
//  Created by WTC Challenge
//

import Foundation

struct Constants {
    // Supabase Configuration
    // IMPORTANT: Replace these with your actual Supabase project credentials
    static let supabaseURL = "YOUR_SUPABASE_URL" // Ex: https://xxxxx.supabase.co
    static let supabaseAnonKey = "YOUR_SUPABASE_ANON_KEY"

    // App Configuration
    static let appName = "WTC Chat"
    static let minimumIOSVersion = "15.0"

    // Deeplink Schemes
    struct Deeplink {
        static let scheme = "deeplink"
        static let products = "deeplink://products"
        static let profile = "deeplink://profile"
        static let orders = "deeplink://orders"
        static let collection = "deeplink://collection"
    }

    // Notification Types
    struct NotificationType {
        static let message = "message"
        static let campaign = "campaign"
        static let system = "system"
    }

    // Database Tables
    struct Tables {
        static let profiles = "profiles"
        static let messages = "messages"
        static let notifications = "notifications"
    }

    // User Defaults Keys
    struct UserDefaultsKeys {
        static let hasSeenOnboarding = "hasSeenOnboarding"
        static let lastSyncDate = "lastSyncDate"
    }
}
