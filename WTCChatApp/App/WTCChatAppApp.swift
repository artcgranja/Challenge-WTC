//
//  WTCChatAppApp.swift
//  WTCChatApp
//
//  Created by WTC Challenge
//

import SwiftUI
import UserNotifications

@main
struct WTCChatAppApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var notificationService = NotificationService.shared

    init() {
        // Request notification permissions
        Task {
            await NotificationService.shared.requestAuthorization()
        }

        // Configure notification delegate
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
                .environmentObject(notificationService)
                .overlay(
                    Group {
                        if notificationService.shouldShowInAppNotification,
                           let notification = notificationService.currentInAppNotification {
                            VStack {
                                InAppNotificationView(
                                    notification: notification,
                                    onTap: {
                                        notificationService.dismissInAppNotification()
                                        // TODO: Navigate to message
                                    },
                                    onDismiss: {
                                        notificationService.dismissInAppNotification()
                                    }
                                )
                                .padding(.top, 50)
                                .transition(.move(edge: .top).combined(with: .opacity))
                                .animation(.spring(), value: notificationService.shouldShowInAppNotification)

                                Spacer()
                            }
                        }
                    }
                )
        }
    }
}

// MARK: - Content View

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        Group {
            if authViewModel.isLoading {
                SplashView()
            } else if authViewModel.isAuthenticated {
                MainTabView()
                    .environmentObject(authViewModel)
            } else {
                LoginView()
                    .environmentObject(authViewModel)
            }
        }
    }
}

// MARK: - Splash View

struct SplashView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.8)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: "message.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.white)

                Text(Constants.appName)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            }
        }
    }
}

// MARK: - Main Tab View

struct MainTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var selectedTab = 0
    @State private var showNotifications = false

    var body: some View {
        TabView(selection: $selectedTab) {
            MessagesListView()
                .environmentObject(authViewModel)
                .tabItem {
                    Label("Mensagens", systemImage: "message.fill")
                }
                .tag(0)

            Button(action: {
                showNotifications = true
            }) {
                EmptyView()
            }
            .tabItem {
                Label("Notificações", systemImage: "bell.fill")
            }
            .tag(1)
        }
        .sheet(isPresented: $showNotifications) {
            NotificationsView()
                .environmentObject(authViewModel)
        }
        .onChange(of: selectedTab) { newValue in
            if newValue == 1 {
                showNotifications = true
                // Reset to messages tab after showing notifications
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    selectedTab = 0
                }
            }
        }
    }
}

// MARK: - Notification Delegate

class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()

    private override init() {
        super.init()
    }

    // Handle notification when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show banner and sound even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }

    // Handle notification tap
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo

        // Navigate to message if messageId is present
        if let messageIdString = userInfo["messageId"] as? String,
           let messageId = UUID(uuidString: messageIdString) {
            // Post notification to navigate to message
            NotificationCenter.default.post(
                name: NSNotification.Name("NavigateToMessage"),
                object: nil,
                userInfo: ["messageId": messageId]
            )
        }

        completionHandler()
    }
}

// MARK: - Preview

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AuthViewModel())
    }
}
