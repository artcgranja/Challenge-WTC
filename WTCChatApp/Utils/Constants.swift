//
//  Constants.swift
//  WTCChatApp
//
//  Created by WTC Challenge
//

import Foundation

struct Constants {
    // Backend API Configuration
    static let apiBaseURL = "http://localhost:8080/api"
    static let wsBaseURL = "ws://localhost:8080/ws"

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

    // User Defaults Keys
    struct UserDefaultsKeys {
        static let hasSeenOnboarding = "hasSeenOnboarding"
        static let lastSyncDate = "lastSyncDate"
        static let accessToken = "access_token"
        static let refreshToken = "refresh_token"
        static let userId = "user_id"
    }
}
